package com.nirbhor.app.domain

import java.time.DayOfWeek
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId

/**
 * Generates dose occurrences from a medicine's schedule. Meal-time tokens resolve to configurable
 * clock times (defaults 08:00 / 14:00 / 21:00); we store the token AND the resolved time, so the
 * patient can override the clock later (README > 3c implementation note).
 */
object DoseScheduler {

    data class PlannedDose(
        val medicineId: String,
        val epochMillis: Long,
        val hour: Int,
        val minute: Int,
        val block: TimeBlock,
    )

    /** Whether [medicine] is due on [date]. */
    fun scheduledOn(medicine: Medicine, date: LocalDate): Boolean {
        if (medicine.paused) return false
        return when (medicine.frequency) {
            Frequency.DAILY -> true
            Frequency.ALTERNATE -> (date.toEpochDay() % 2L == 0L)
            Frequency.WEEKDAYS, Frequency.WEEKLY -> {
                val bit = 1 shl (date.dayOfWeek.value - 1) // Mon=bit0 … Sun=bit6
                (medicine.weekdaysMask and bit) != 0
            }
        }
    }

    /** All doses [medicine] should have on [date]. */
    fun dosesFor(medicine: Medicine, date: LocalDate, zone: ZoneId = ZoneId.systemDefault()): List<PlannedDose> {
        if (!scheduledOn(medicine, date)) return emptyList()
        val times = medicine.resolvedTimes.ifEmpty {
            medicine.timeTokens.map { blockDefaultTime(TimeBlock.fromToken(it)) }
        }
        return medicine.timeTokens.mapIndexedNotNull { i, token ->
            val block = TimeBlock.fromToken(token)
            val hhmm = times.getOrNull(i) ?: blockDefaultTime(block)
            val (h, m) = parseHhmm(hhmm) ?: return@mapIndexedNotNull null
            val instant = date.atTime(LocalTime.of(h, m)).atZone(zone).toInstant()
            PlannedDose(medicine.id, instant.toEpochMilli(), h, m, block)
        }
    }

    fun blockDefaultTime(block: TimeBlock): String = "%02d:00".format(block.defaultHour)

    fun parseHhmm(s: String): Pair<Int, Int>? {
        val parts = s.split(":")
        if (parts.size != 2) return null
        val h = parts[0].toIntOrNull() ?: return null
        val m = parts[1].toIntOrNull() ?: return null
        if (h !in 0..23 || m !in 0..59) return null
        return h to m
    }

    /** Snooze from now when delivery was late, never from an already-past scheduled time. */
    fun snoozedEpochMillis(scheduledEpochMillis: Long, nowEpochMillis: Long, minutes: Int): Long? {
        if (minutes <= 0) return null
        return maxOf(scheduledEpochMillis, nowEpochMillis) + minutes.toLong() * 60_000L
    }

    fun weekdayBit(day: DayOfWeek): Int = 1 shl (day.value - 1)
}
