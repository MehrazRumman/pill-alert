package com.nirbhor.app.domain

import com.nirbhor.app.ui.marks.MarkShape
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.DayOfWeek
import java.time.LocalDate

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

    private fun medicine(
        frequency: Frequency,
        weekdaysMask: Int = 0,
        resolvedTimes: List<String> = listOf("08:00"),
    ) = Medicine(
        id = "test",
        displayName = "Test",
        packName = "Test",
        strength = "500 mg",
        form = "tablet",
        condition = "",
        mark = MarkShape.FilledCircle,
        markColor = 0xFF2F6B5B,
        dosePerIntake = 1f,
        foodRelation = FoodRelation.NONE,
        frequency = frequency,
        weekdaysMask = weekdaysMask,
        timeTokens = listOf(TimeBlock.MORNING.token),
        resolvedTimes = resolvedTimes,
        stockCount = 30,
        stockUpdatedAt = 0,
        highRisk = false,
        paused = false,
    )
}
