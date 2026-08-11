package com.nirbhor.app.domain

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AppSettingsTest {
    @Test fun systemLocaleFollowsDevice() {
        val settings = AppSettings(localePref = LocalePref.SYSTEM)
        assertTrue(settings.isBangla(deviceIsBangla = true))
        assertFalse(settings.isBangla(deviceIsBangla = false))
    }

    @Test fun explicitLocaleOverridesDevice() {
        assertTrue(AppSettings(localePref = LocalePref.BN).isBangla(deviceIsBangla = false))
        assertFalse(AppSettings(localePref = LocalePref.EN).isBangla(deviceIsBangla = true))
    }

    @Test fun localeDefaultsChooseExpectedClockFormat() {
        val settings = AppSettings(timeFormat = null)
        assertFalse(settings.is24Hour(bangla = true))
        assertTrue(settings.is24Hour(bangla = false))
    }

    @Test fun explicitClockFormatOverridesLocale() {
        assertTrue(AppSettings(timeFormat = TimeFormat.H24).is24Hour(bangla = true))
        assertFalse(AppSettings(timeFormat = TimeFormat.H12).is24Hour(bangla = false))
    }
}
