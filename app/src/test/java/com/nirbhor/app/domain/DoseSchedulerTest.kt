package com.nirbhor.app.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.ZoneId

class DoseSchedulerTest {
    @Test fun parsesOnlyValidClockTimes() {
        assertEquals(23 to 59, DoseScheduler.parseHhmm("23:59"))
        assertNull(DoseScheduler.parseHhmm("24:00"))
        assertNull(DoseScheduler.parseHhmm("12:60"))
        assertNull(DoseScheduler.parseHhmm("not-a-time"))
    }

    @Test fun pauseAndSelectedDaysAreRespected() {
        val monday = LocalDate.of(2026, 8, 10)
        val medicine = medicine(
            frequency = Frequency.WEEKLY,
            weekdaysMask = DoseScheduler.weekdayBit(DayOfWeek.MONDAY),
        )
        assertTrue(DoseScheduler.scheduledOn(medicine, monday))
        assertFalse(DoseScheduler.scheduledOn(medicine, monday.plusDays(1)))
        assertFalse(DoseScheduler.scheduledOn(medicine.copy(paused = true), monday))
    }

    @Test fun invalidStoredTimeIsSkippedWithoutCrashing() {
        val doses = DoseScheduler.dosesFor(
            medicine(frequency = Frequency.DAILY, resolvedTimes = listOf("29:99")),
            LocalDate.of(2026, 8, 10),
        )
        assertTrue(doses.isEmpty())
    }

    @Test fun parsesBoundaryAndFlexibleHourClockTimes() {
        assertEquals(0 to 0, DoseScheduler.parseHhmm("00:00"))
        assertEquals(8 to 5, DoseScheduler.parseHhmm("8:05"))
        assertNull(DoseScheduler.parseHhmm("-1:00"))
        assertNull(DoseScheduler.parseHhmm("12"))
        assertNull(DoseScheduler.parseHhmm("12:30:00"))
        assertNull(DoseScheduler.parseHhmm(" 08:00 "))
    }

    @Test fun dailyMedicineIsScheduledEveryDay() {
        val medicine = testMedicine()
        val start = LocalDate.of(2026, 1, 1)
        repeat(14) { offset -> assertTrue(DoseScheduler.scheduledOn(medicine, start.plusDays(offset.toLong()))) }
    }

    @Test fun alternateMedicineUsesStableEpochDayParity() {
        val medicine = testMedicine(frequency = Frequency.ALTERNATE)
        val even = LocalDate.ofEpochDay(20_000)
        assertTrue(DoseScheduler.scheduledOn(medicine, even))
        assertFalse(DoseScheduler.scheduledOn(medicine, even.plusDays(1)))
        assertTrue(DoseScheduler.scheduledOn(medicine, even.plusDays(2)))
    }

    @Test fun weekdayMaskSupportsMultipleDaysAndBothFrequencyNames() {
        val monday = LocalDate.of(2026, 8, 10)
        val mask = DoseScheduler.weekdayBit(DayOfWeek.MONDAY) or DoseScheduler.weekdayBit(DayOfWeek.FRIDAY)
        for (frequency in listOf(Frequency.WEEKDAYS, Frequency.WEEKLY)) {
            val medicine = testMedicine(frequency = frequency, weekdaysMask = mask)
            assertTrue(DoseScheduler.scheduledOn(medicine, monday))
            assertFalse(DoseScheduler.scheduledOn(medicine, monday.plusDays(1)))
            assertTrue(DoseScheduler.scheduledOn(medicine, monday.plusDays(4)))
        }
    }

    @Test fun zeroWeekdayMaskSchedulesNothing() {
        val medicine = testMedicine(frequency = Frequency.WEEKLY, weekdaysMask = 0)
        val start = LocalDate.of(2026, 8, 10)
        repeat(7) { assertFalse(DoseScheduler.scheduledOn(medicine, start.plusDays(it.toLong()))) }
    }

    @Test fun createsParallelDosesWithCorrectBlocksAndTimes() {
        val date = LocalDate.of(2026, 8, 10)
        val zone = ZoneId.of("Asia/Dhaka")
        val doses = DoseScheduler.dosesFor(
            testMedicine(
                timeTokens = listOf("morning", "noon", "night"),
                resolvedTimes = listOf("07:15", "13:45", "22:05"),
            ),
            date,
            zone,
        )
        assertEquals(listOf(TimeBlock.MORNING, TimeBlock.NOON, TimeBlock.NIGHT), doses.map { it.block })
        assertEquals(listOf(7 to 15, 13 to 45, 22 to 5), doses.map { it.hour to it.minute })
        assertEquals(
            date.atTime(7, 15).atZone(zone).toInstant().toEpochMilli(),
            doses.first().epochMillis,
        )
    }

    @Test fun emptyResolvedTimesUseBlockDefaults() {
        val doses = DoseScheduler.dosesFor(
            testMedicine(
                timeTokens = listOf("morning", "noon", "night"),
                resolvedTimes = emptyList(),
            ),
            LocalDate.of(2026, 8, 10),
        )
        assertEquals(listOf(8 to 0, 14 to 0, 21 to 0), doses.map { it.hour to it.minute })
    }

    @Test fun missingResolvedTimeFallsBackForOnlyThatBlock() {
        val doses = DoseScheduler.dosesFor(
            testMedicine(timeTokens = listOf("morning", "night"), resolvedTimes = listOf("09:30")),
            LocalDate.of(2026, 8, 10),
        )
        assertEquals(listOf(9 to 30, 21 to 0), doses.map { it.hour to it.minute })
    }

    @Test fun pausedMedicineProducesNoDoses() {
        assertTrue(
            DoseScheduler.dosesFor(testMedicine(paused = true), LocalDate.of(2026, 8, 10)).isEmpty(),
        )
    }

    @Test fun blockTokensAndDefaultsAreStable() {
        assertEquals(TimeBlock.NOON, TimeBlock.fromToken("noon"))
        assertEquals(TimeBlock.MORNING, TimeBlock.fromToken("unknown"))
        assertEquals("08:00", DoseScheduler.blockDefaultTime(TimeBlock.MORNING))
        assertEquals("14:00", DoseScheduler.blockDefaultTime(TimeBlock.NOON))
        assertEquals("21:00", DoseScheduler.blockDefaultTime(TimeBlock.NIGHT))
    }

    @Test fun snoozeUsesNowWhenOriginalAlarmIsAlreadyLate() {
        val now = 10_000_000L
        assertEquals(now + 10 * 60_000L, DoseScheduler.snoozedEpochMillis(now - 60_000L, now, 10))
    }

    @Test fun earlySnoozeUsesOriginalScheduleAndRejectsInvalidDuration() {
        val now = 10_000_000L
        val scheduled = now + 60_000L
        assertEquals(scheduled + 5 * 60_000L, DoseScheduler.snoozedEpochMillis(scheduled, now, 5))
        assertNull(DoseScheduler.snoozedEpochMillis(scheduled, now, 0))
        assertNull(DoseScheduler.snoozedEpochMillis(scheduled, now, -1))
    }

    private fun medicine(
        frequency: Frequency,
        weekdaysMask: Int = 0,
        resolvedTimes: List<String> = listOf("08:00"),
    ) = testMedicine(frequency = frequency, weekdaysMask = weekdaysMask, resolvedTimes = resolvedTimes)
}
