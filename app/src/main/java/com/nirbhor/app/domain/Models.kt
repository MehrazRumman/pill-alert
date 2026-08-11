package com.nirbhor.app.domain

import com.nirbhor.app.ui.marks.MarkShape

/** The three time blocks the home timeline groups doses into. Tokens resolve to configurable clocks. */
enum class TimeBlock(val token: String, val defaultHour: Int) {
    MORNING("morning", 8),   // সকাল · default 08:00
    NOON("noon", 14),        // দুপুর · default 14:00
    NIGHT("night", 21);      // রাত  · default 21:00

    companion object {
        fun fromToken(t: String): TimeBlock = entries.firstOrNull { it.token == t } ?: MORNING
    }
}

/** খাবারের আগে না পরে — meal relation. */
enum class FoodRelation { BEFORE, AFTER, NONE }

enum class Frequency { DAILY, ALTERNATE, WEEKDAYS, WEEKLY }

/** Dose-occurrence status vocabulary (README > Dose Status Vocabulary). */
enum class DoseStatus { UPCOMING, TAKEN, TAKEN_LATE, MISSED, SKIPPED }

/** Where a confirmation came from. */
enum class DoseSource { ALARM, HOME, RECOVERY_SHEET, CAREGIVER }

/** How a linked caregiver is told about problems. Channels are independent and can all be on. */
enum class CaregiverChannel { EMAIL, SMS, APP }

enum class DigestFrequency { DAILY_DIGEST, IMMEDIATE }

/** UI-facing medicine model (localised display name + the Latin pack name are both kept). */
data class Medicine(
    val id: String,
    val displayName: String,     // localised name shown to the patient
    val packName: String,        // Latin name as printed on the pack (stays Latin)
    val strength: String,        // e.g. "৫০০ মি.গ্রা." / "500 mg"
    val form: String,            // e.g. ট্যাবলেট / tablet
    val condition: String,       // what the patient recognises, e.g. ডায়াবেটিস / diabetes
    val mark: MarkShape,
    val markColor: Long,         // ARGB; stored, never derived
    val dosePerIntake: Float,    // supports halves (0.5, 1, 2, 3)
    val foodRelation: FoodRelation,
    val frequency: Frequency,
    val weekdaysMask: Int,       // bitmask Mon..Sun when frequency == WEEKDAYS/WEEKLY
    val timeTokens: List<String>,          // morning/noon/night
    val resolvedTimes: List<String>,       // "HH:mm" resolved clock times, parallel to blocks
    val stockCount: Int,
    val stockUpdatedAt: Long,
    val highRisk: Boolean,       // gates press-and-hold confirmation
    val paused: Boolean,
)

/** A single scheduled dose for a given day/time. */
data class DoseOccurrence(
    val id: Long,
    val medicineId: String,
    val scheduledEpochMillis: Long,
    val hour: Int,
    val minute: Int,
    val block: TimeBlock,
    val status: DoseStatus,
    val confirmedAt: Long?,
    val source: DoseSource?,
)

/** A dose joined with its medicine — what timeline / alarm / record rows actually render. */
data class DoseWithMedicine(
    val dose: DoseOccurrence,
    val medicine: Medicine,
)

/** A time block on the home timeline, with its due doses. */
data class TimelineBlock(
    val block: TimeBlock,
    val hour: Int,
    val minute: Int,
    val doses: List<DoseWithMedicine>,
) {
    val allTaken: Boolean get() = doses.isNotEmpty() && doses.all {
        it.dose.status == DoseStatus.TAKEN || it.dose.status == DoseStatus.TAKEN_LATE
    }
    val anyDueNow: Boolean get() = doses.any { it.dose.status == DoseStatus.UPCOMING }
}

data class Caregiver(
    val id: String,
    val name: String,
    val relationship: String,
    val email: String,
    val emailVerified: Boolean,
    val phone: String,
    val channels: Set<CaregiverChannel>,
    val digestFrequency: DigestFrequency,
    val escalateOnSecondMiss: Boolean,
    val notifyOnMissedTwice: Boolean,
    val notifyOnOutOfStock: Boolean,
    val weeklySummary: Boolean,
)

data class AlertLogItem(
    val id: Long,
    val kind: String,        // missed | summary | low-stock | reminder
    val message: String,
    val sentAtMillis: Long,
    val outcome: String,
)

/** Derived numbers the UI needs but that aren't stored. */
data class DailyProgress(val taken: Int, val total: Int) {
    val remaining: Int get() = (total - taken).coerceAtLeast(0)
    val fraction: Float get() = if (total == 0) 0f else taken.toFloat() / total
}

data class StockStatus(
    val medicineId: String,
    val count: Int,
    val daysRemaining: Int,
    val isLow: Boolean,          // ≤ 5 days
    val runsOutEpochMillis: Long?,
)
