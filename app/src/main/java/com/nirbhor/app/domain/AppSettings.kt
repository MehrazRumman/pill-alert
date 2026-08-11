package com.nirbhor.app.domain

/** ভাষা — locale preference. SYSTEM follows the device locale (the default). */
enum class LocalePref { SYSTEM, BN, EN }

enum class TimeFormat { H12, H24 }

/** App-level settings (README > State Management > App-level). Persisted in DataStore. */
data class AppSettings(
    val localePref: LocalePref = LocalePref.SYSTEM,
    val timeFormat: TimeFormat? = null,   // null → locale default (BN→12h, EN→24h)
    val biggerText: Boolean = false,
    val readAloud: Boolean = true,        // ON in Bangla; TTS speaks the medicine name at alarm
    val fullScreenAlarm: Boolean = true,
    val alarmSound: String = "default",
    val repeatEveryMinutes: Int = 10,
    val repeatMax: Int = 3,
    val onboardingComplete: Boolean = false,
    val notificationPrimingShown: Boolean = false,
) {
    /** Resolves the effective Bangla flag given the device's Bangla state. */
    fun isBangla(deviceIsBangla: Boolean): Boolean = when (localePref) {
        LocalePref.BN -> true
        LocalePref.EN -> false
        LocalePref.SYSTEM -> deviceIsBangla
    }

    /** Resolves the effective 24-hour flag. BN defaults to 12h, EN to 24h. */
    fun is24Hour(bangla: Boolean): Boolean = when (timeFormat) {
        TimeFormat.H24 -> true
        TimeFormat.H12 -> false
        null -> !bangla
    }
}
