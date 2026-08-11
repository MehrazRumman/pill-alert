package com.nirbhor.app.ui.i18n

import org.junit.Assert.assertEquals
import org.junit.Test

class NumeralsTest {
    @Test fun convertsOnlyAsciiDigitsToBangla() {
        assertEquals("ওষুধ ১২৩.৪৫ mg", Numerals.digits("ওষুধ 123.45 mg", bangla = true))
        assertEquals("123.45", Numerals.digits("123.45", bangla = false))
        assertEquals("", Numerals.digits("", bangla = true))
    }

    @Test fun formatsPositiveZeroAndNegativeNumbers() {
        assertEquals("০", Numerals.number(0, bangla = true))
        assertEquals("-১২", Numerals.number(-12, bangla = true))
        assertEquals("42", Numerals.number(42, bangla = false))
    }

    @Test fun formatsPercentWithoutChangingSymbol() {
        assertEquals("৭৫%", Numerals.percent(75, bangla = true))
        assertEquals("75%", Numerals.percent(75, bangla = false))
    }

    @Test fun banglaPeriodsCoverEveryBoundary() {
        val expected = mapOf(
            0 to "রাত", 3 to "রাত", 4 to "ভোর", 5 to "ভোর", 6 to "সকাল", 11 to "সকাল",
            12 to "দুপুর", 14 to "দুপুর", 15 to "বিকাল", 17 to "বিকাল",
            18 to "সন্ধ্যা", 19 to "সন্ধ্যা", 20 to "রাত", 23 to "রাত",
        )
        expected.forEach { (hour, period) -> assertEquals(period, Numerals.banglaPeriod(hour)) }
    }

    @Test fun formatsBanglaTwelveHourClockAtMidnightNoonAndEvening() {
        assertEquals("রাত ১২:০০", Numerals.time(0, 0, bangla = true, is24 = false))
        assertEquals("দুপুর ১২:০৫", Numerals.time(12, 5, bangla = true, is24 = true))
        assertEquals("রাত ৯:৩০", Numerals.time(21, 30, bangla = true, is24 = false))
    }

    @Test fun formatsEnglishTwentyFourHourClockWithPadding() {
        assertEquals("00:05", Numerals.time(0, 5, bangla = false, is24 = true))
        assertEquals("08:00", Numerals.time(8, 0, bangla = false, is24 = true))
        assertEquals("23:59", Numerals.time(23, 59, bangla = false, is24 = true))
    }

    @Test fun formatsEnglishTwelveHourClockAtBoundaries() {
        assertEquals("12:00 AM", Numerals.time(0, 0, bangla = false, is24 = false))
        assertEquals("11:59 AM", Numerals.time(11, 59, bangla = false, is24 = false))
        assertEquals("12:00 PM", Numerals.time(12, 0, bangla = false, is24 = false))
        assertEquals("9:07 PM", Numerals.time(21, 7, bangla = false, is24 = false))
    }
}
