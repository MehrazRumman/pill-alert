package com.nirbhor.app.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class StockCalculatorTest {
    @Test fun dailyStockAccountsForDoseAndTimes() {
        assertEquals(10, StockCalculator.estimatedDays(30, 1.5f, 2, Frequency.DAILY, 0))
    }

    @Test fun alternateScheduleLastsTwiceAsLongAsDaily() {
        assertEquals(20, StockCalculator.estimatedDays(10, 1f, 1, Frequency.ALTERNATE, 0))
    }

    @Test fun selectedWeekdaysUseActualMaskCount() {
        val mondayAndFriday = DoseScheduler.weekdayBit(java.time.DayOfWeek.MONDAY) or
            DoseScheduler.weekdayBit(java.time.DayOfWeek.FRIDAY)
        assertEquals(35, StockCalculator.estimatedDays(10, 1f, 1, Frequency.WEEKLY, mondayAndFriday))
    }

    @Test fun zeroStockHasZeroDays() {
        assertEquals(0, StockCalculator.estimatedDays(0, 1f, 1, Frequency.DAILY, 0))
    }

    @Test fun pausedOrInvalidSchedulesHaveNoDepletionEstimate() {
        assertNull(StockCalculator.estimatedDays(30, 1f, 1, Frequency.DAILY, 0, paused = true))
        assertNull(StockCalculator.estimatedDays(30, 1f, 0, Frequency.DAILY, 0))
        assertNull(StockCalculator.estimatedDays(30, 0f, 1, Frequency.DAILY, 0))
        assertNull(StockCalculator.estimatedDays(30, 1f, 1, Frequency.WEEKLY, 0))
    }
}
