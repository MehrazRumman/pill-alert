package com.nirbhor.app.data

import android.content.Context
import com.nirbhor.app.domain.DoseOccurrence
import com.nirbhor.app.domain.DoseScheduler
import com.nirbhor.app.domain.DoseSource
import com.nirbhor.app.domain.DoseStatus
import com.nirbhor.app.domain.DoseWithMedicine
import com.nirbhor.app.domain.Medicine
import com.nirbhor.app.domain.StockStatus
import com.nirbhor.app.domain.TimeBlock
import com.nirbhor.app.domain.TimelineBlock
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.map
import java.time.LocalDate
import java.time.ZoneId
import kotlin.math.ceil

/**
 * Single source of truth for medicines, doses and caregivers. Local-first: all writes are optimistic
 * and immediate; caregiver delivery / sync happen out of band (README > Offline).
 */
class NirbhorRepository private constructor(
    private val db: NirbhorDatabase,
    private val zone: ZoneId = ZoneId.systemDefault(),
) {
    private val medicineDao = db.medicineDao()
    private val doseDao = db.doseDao()
    private val caregiverDao = db.caregiverDao()

    // ---- Medicines --------------------------------------------------------

    val medicines: Flow<List<Medicine>> = medicineDao.observeAll().map { list -> list.map { it.toDomain() } }

    fun medicine(id: String): Flow<Medicine?> = medicineDao.observe(id).map { it?.toDomain() }

    suspend fun upsertMedicine(medicine: Medicine) {
        val existing = medicineDao.get(medicine.id)
        medicineDao.upsert(medicine.toEntity(createdAt = existing?.createdAt ?: System.currentTimeMillis()))
        val scheduleChanged = existing == null || existing.toDomain().let { old ->
            old.frequency != medicine.frequency ||
                old.weekdaysMask != medicine.weekdaysMask ||
                old.timeTokens != medicine.timeTokens ||
                old.resolvedTimes != medicine.resolvedTimes ||
                old.paused != medicine.paused
        }
        if (scheduleChanged) regenerateUpcoming(medicine.id)
    }

    suspend fun deleteMedicine(id: String) {
        doseDao.deleteForMedicine(id)
        medicineDao.delete(id)
    }

    suspend fun addStock(id: String, delta: Int) {
        medicineDao.adjustStock(id, delta, System.currentTimeMillis())
    }

    suspend fun setStock(id: String, count: Int) {
        medicineDao.setStock(id, count.coerceAtLeast(0), System.currentTimeMillis())
    }

    // ---- Doses ------------------------------------------------------------

    private fun dayBounds(date: LocalDate): Pair<Long, Long> {
        val start = date.atStartOfDay(zone).toInstant().toEpochMilli()
        val end = date.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        return start to end
    }

    /** Ensures every scheduled dose for [date] exists in the DB (idempotent). */
    suspend fun ensureDosesFor(date: LocalDate) {
        val (start, end) = dayBounds(date)
        val existing = doseDao.getBetween(start, end).map { it.medicineId to it.scheduledEpochMillis }.toSet()
        val meds = medicineDao.getAll().map { it.toDomain() }
        val toInsert = meds.flatMap { DoseScheduler.dosesFor(it, date, zone) }
            .filter { (it.medicineId to it.epochMillis) !in existing }
            .map {
                DoseEntity(
                    medicineId = it.medicineId,
                    scheduledEpochMillis = it.epochMillis,
                    hour = it.hour, minute = it.minute,
                    block = it.block.name,
                    status = DoseStatus.UPCOMING.name,
                    confirmedAt = null, source = null,
                )
            }
        if (toInsert.isNotEmpty()) doseDao.insertAll(toInsert)
    }

    /** Regenerates future UPCOMING doses for a medicine after a schedule edit. */
    private suspend fun regenerateUpcoming(medicineId: String) {
        val today = LocalDate.now(zone)
        doseDao.deleteUpcomingForMedicine(medicineId, dayBounds(today).first)
        for (i in 0..14) ensureDosesFor(today.plusDays(i.toLong()))
    }

    /** Today's doses grouped into the three time blocks, joined with their medicines. */
    fun timelineFor(date: LocalDate): Flow<List<TimelineBlock>> {
        val (start, end) = dayBounds(date)
        return combine(doseDao.observeBetween(start, end), medicineDao.observeAll()) { doses, meds ->
            val byId = meds.associateBy({ it.id }, { it.toDomain() })
            val joined = doses.mapNotNull { d ->
                val m = byId[d.medicineId] ?: return@mapNotNull null
                DoseWithMedicine(d.toDomain(), m)
            }
            TimeBlock.entries.map { block ->
                val blockDoses = joined.filter { it.dose.block == block }
                    .sortedBy { it.dose.scheduledEpochMillis }
                val time = blockDoses.firstOrNull()?.dose
                TimelineBlock(
                    block = block,
                    hour = time?.hour ?: block.defaultHour,
                    minute = time?.minute ?: 0,
                    doses = blockDoses,
                )
            }.filter { it.doses.isNotEmpty() }
        }
    }

    suspend fun markTaken(doseId: Long, source: DoseSource = DoseSource.HOME, late: Boolean? = null) {
        val dose = doseDao.get(doseId) ?: return
        val now = System.currentTimeMillis()
        val wasLate = late ?: (now > dose.scheduledEpochMillis + 30 * 60_000L)
        val status = if (wasLate) DoseStatus.TAKEN_LATE else DoseStatus.TAKEN
        val changed = doseDao.setStatusIf(
            id = doseId,
            status = status.name,
            confirmedAt = now,
            source = source.name,
            allowedStatuses = listOf(DoseStatus.UPCOMING.name, DoseStatus.MISSED.name, DoseStatus.SKIPPED.name),
        )
        if (changed == 0) return
        // Decrement stock by the medicine's dose (rounded up for halves).
        val m = medicineDao.get(dose.medicineId) ?: return
        val used = ceil(m.dosePerIntake.toDouble()).toInt().coerceAtLeast(1)
        medicineDao.adjustStock(m.id, -used, System.currentTimeMillis())
    }

    suspend fun undoTaken(doseId: Long) {
        val dose = doseDao.get(doseId) ?: return
        val changed = doseDao.setStatusIf(
            id = doseId,
            status = DoseStatus.UPCOMING.name,
            confirmedAt = null,
            source = null,
            allowedStatuses = listOf(DoseStatus.TAKEN.name, DoseStatus.TAKEN_LATE.name),
        )
        if (changed == 0) return
        val m = medicineDao.get(dose.medicineId) ?: return
        val used = ceil(m.dosePerIntake.toDouble()).toInt().coerceAtLeast(1)
        medicineDao.adjustStock(m.id, used, System.currentTimeMillis())
    }

    suspend fun skipDose(doseId: Long, source: DoseSource = DoseSource.RECOVERY_SHEET) {
        doseDao.setStatusIf(
            id = doseId,
            status = DoseStatus.SKIPPED.name,
            confirmedAt = System.currentTimeMillis(),
            source = source.name,
            allowedStatuses = listOf(DoseStatus.UPCOMING.name, DoseStatus.MISSED.name),
        )
    }

    /** Marks unanswered doses missed after a grace period, keeping adherence records truthful. */
    suspend fun markOverdueDoses(graceMinutes: Int = 30) {
        val cutoff = System.currentTimeMillis() - graceMinutes.coerceAtLeast(0).toLong() * 60_000L
        doseDao.markOverdue(cutoff)
    }

    /** Snooze +10 min (repeats handled by the alarm scheduler); shifts the scheduled time. */
    suspend fun snoozeDose(doseId: Long, minutes: Int = 10) {
        val dose = doseDao.get(doseId) ?: return
        if (dose.status != DoseStatus.UPCOMING.name || minutes <= 0) return
        val shiftedEpoch = dose.scheduledEpochMillis + minutes.toLong() * 60_000L
        val shiftedTime = java.time.Instant.ofEpochMilli(shiftedEpoch).atZone(zone).toLocalTime()
        doseDao.update(
            dose.copy(
                scheduledEpochMillis = shiftedEpoch,
                hour = shiftedTime.hour,
                minute = shiftedTime.minute,
            ),
        )
    }

    // ---- Derivations ------------------------------------------------------

    fun stockStatuses(): Flow<List<StockStatus>> = medicines.map { meds ->
        meds.map { m ->
            val dosesPerScheduledDay = m.timeTokens.size.coerceAtLeast(1) * m.dosePerIntake
            val scheduledDaysPerWeek = when (m.frequency) {
                com.nirbhor.app.domain.Frequency.DAILY -> 7f
                com.nirbhor.app.domain.Frequency.ALTERNATE -> 3.5f
                com.nirbhor.app.domain.Frequency.WEEKDAYS, com.nirbhor.app.domain.Frequency.WEEKLY ->
                    Integer.bitCount(m.weekdaysMask and 0x7F).coerceAtLeast(1).toFloat()
            }
            val perDay = dosesPerScheduledDay * (scheduledDaysPerWeek / 7f)
            val days = if (perDay <= 0f) Int.MAX_VALUE else (m.stockCount / perDay).toInt()
            val runsOut = if (days == Int.MAX_VALUE) null else
                LocalDate.now(zone).plusDays(days.toLong()).atStartOfDay(zone).toInstant().toEpochMilli()
            StockStatus(m.id, m.stockCount, days, isLow = days <= 5, runsOutEpochMillis = runsOut)
        }
    }

    data class AdherenceWindow(val taken: Int, val missed: Int, val total: Int, val streakDays: Int) {
        val percent: Int get() = if (total == 0) 0 else ((taken.toFloat() / total) * 100).toInt()
    }

    suspend fun adherenceOver(days: Int): AdherenceWindow {
        val today = LocalDate.now(zone)
        val start = today.minusDays((days - 1).toLong()).atStartOfDay(zone).toInstant().toEpochMilli()
        val end = today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        val doses = doseDao.getBetween(start, end).map { it.toDomain() }
        val taken = doses.count { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE }
        val missed = doses.count { it.status == DoseStatus.MISSED }
        val total = doses.count { it.status != DoseStatus.UPCOMING }
        return AdherenceWindow(taken, missed, total, streak(doses))
    }

    private fun streak(doses: List<DoseOccurrence>): Int {
        val byDay = doses.groupBy {
            java.time.Instant.ofEpochMilli(it.scheduledEpochMillis).atZone(zone).toLocalDate()
        }
        var streak = 0
        var day = LocalDate.now(zone).minusDays(1) // count fully-completed past days
        while (true) {
            val d = byDay[day] ?: break
            val done = d.isNotEmpty() && d.all { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE }
            if (!done) break
            streak++
            day = day.minusDays(1)
        }
        return streak
    }

    /** Upcoming doses within [withinMillis] from now — used by the alarm scheduler. */
    suspend fun upcomingDoses(withinMillis: Long = 48L * 3600_000L): List<DoseOccurrence> {
        val now = System.currentTimeMillis()
        return doseDao.getBetween(now, now + withinMillis).map { it.toDomain() }
            .filter { it.status == DoseStatus.UPCOMING }
            .sortedBy { it.scheduledEpochMillis }
    }

    /** All doses scheduled around [epochMillis] (±[toleranceMin]) joined with medicines — the alarm payload. */
    suspend fun dosesAround(epochMillis: Long, toleranceMin: Int = 30): List<DoseWithMedicine> {
        val tol = toleranceMin * 60_000L
        val doses = doseDao.getBetween(epochMillis - tol, epochMillis + tol).map { it.toDomain() }
            .filter { it.status == DoseStatus.UPCOMING }
        val meds = medicineDao.getAll().map { it.toDomain() }.associateBy { it.id }
        return doses.mapNotNull { d -> meds[d.medicineId]?.let { DoseWithMedicine(d, it) } }
    }

    suspend fun doseWithMedicine(doseId: Long): DoseWithMedicine? {
        val d = doseDao.get(doseId)?.toDomain() ?: return null
        val m = medicineDao.get(d.medicineId)?.toDomain() ?: return null
        return DoseWithMedicine(d, m)
    }

    enum class DayState { FULL, PARTIAL, MISSED, FUTURE, EMPTY }
    data class DayCell(val date: LocalDate, val state: DayState)
    data class MedAdherence(val medicine: Medicine, val taken: Int, val total: Int) {
        val percent: Int get() = if (total == 0) 0 else ((taken.toFloat() / total) * 100).toInt()
    }

    /** Per-day completion cells for the record grid (oldest→newest), covering [days] ending today. */
    suspend fun dayCells(days: Int): List<DayCell> {
        val today = LocalDate.now(zone)
        val start = today.minusDays((days - 1).toLong()).atStartOfDay(zone).toInstant().toEpochMilli()
        val end = today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        val byDay = doseDao.getBetween(start, end).map { it.toDomain() }.groupBy {
            java.time.Instant.ofEpochMilli(it.scheduledEpochMillis).atZone(zone).toLocalDate()
        }
        return (0 until days).map { i ->
            val date = today.minusDays((days - 1 - i).toLong())
            val d = byDay[date].orEmpty()
            val state = when {
                date.isAfter(today) -> DayState.FUTURE
                d.isEmpty() -> DayState.EMPTY
                date == today && d.any { it.status == DoseStatus.UPCOMING } ->
                    if (d.any { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE }) DayState.PARTIAL else DayState.FUTURE
                d.all { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE } -> DayState.FULL
                d.all { it.status == DoseStatus.MISSED || it.status == DoseStatus.SKIPPED } -> DayState.MISSED
                d.any { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE } -> DayState.PARTIAL
                else -> DayState.MISSED
            }
            DayCell(date, state)
        }
    }

    /** Per-medicine adherence over the last [days]. */
    suspend fun perMedicineAdherence(days: Int): List<MedAdherence> {
        val today = LocalDate.now(zone)
        val start = today.minusDays((days - 1).toLong()).atStartOfDay(zone).toInstant().toEpochMilli()
        val end = today.plusDays(1).atStartOfDay(zone).toInstant().toEpochMilli() - 1
        val meds = medicineDao.getAll().map { it.toDomain() }
        val doses = doseDao.getBetween(start, end).map { it.toDomain() }.groupBy { it.medicineId }
        return meds.map { m ->
            val d = doses[m.id].orEmpty().filter { it.status != DoseStatus.UPCOMING }
            val taken = d.count { it.status == DoseStatus.TAKEN || it.status == DoseStatus.TAKEN_LATE }
            NirbhorRepository.MedAdherence(m, taken, d.size)
        }
    }

    // ---- Caregiver --------------------------------------------------------

    val primaryCaregiver = caregiverDao.observePrimary().map { it?.toDomain() }
    fun alertLog(limit: Int = 20) = caregiverDao.observeAlerts(limit).map { list ->
        list.map { com.nirbhor.app.domain.AlertLogItem(it.id, it.kind, it.message, it.sentAtMillis, it.outcome) }
    }
    suspend fun upsertCaregiver(caregiver: com.nirbhor.app.domain.Caregiver) = caregiverDao.upsert(caregiver.toEntity())

    companion object {
        @Volatile private var instance: NirbhorRepository? = null
        fun get(context: Context): NirbhorRepository =
            instance ?: synchronized(this) {
                instance ?: NirbhorRepository(NirbhorDatabase.get(context)).also { instance = it }
            }
    }
}
