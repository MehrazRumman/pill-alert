package com.nirbhor.app.data

import android.content.Context
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.intPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.nirbhor.app.domain.AppSettings
import com.nirbhor.app.domain.LocalePref
import com.nirbhor.app.domain.TimeFormat
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore by preferencesDataStore(name = "settings")

/** Persists [AppSettings] in a Preferences DataStore. */
class SettingsStore(private val context: Context) {

    private object Keys {
        val locale = stringPreferencesKey("locale_pref")
        val timeFormat = stringPreferencesKey("time_format")
        val biggerText = booleanPreferencesKey("bigger_text")
        val readAloud = booleanPreferencesKey("read_aloud")
        val fullScreenAlarm = booleanPreferencesKey("full_screen_alarm")
        val alarmSound = stringPreferencesKey("alarm_sound")
        val repeatEvery = intPreferencesKey("repeat_every")
        val repeatMax = intPreferencesKey("repeat_max")
        val onboarding = booleanPreferencesKey("onboarding_complete")
        val priming = booleanPreferencesKey("priming_shown")
        val inboxReadSignature = stringPreferencesKey("inbox_read_signature")
    }

    val settings: Flow<AppSettings> = context.dataStore.data.map { p ->
        AppSettings(
            localePref = p[Keys.locale]?.let { runCatching { LocalePref.valueOf(it) }.getOrNull() } ?: LocalePref.SYSTEM,
            timeFormat = p[Keys.timeFormat]?.let { runCatching { TimeFormat.valueOf(it) }.getOrNull() },
            biggerText = p[Keys.biggerText] ?: false,
            readAloud = p[Keys.readAloud] ?: true,
            fullScreenAlarm = p[Keys.fullScreenAlarm] ?: true,
            alarmSound = p[Keys.alarmSound] ?: "default",
            repeatEveryMinutes = p[Keys.repeatEvery] ?: 10,
            repeatMax = p[Keys.repeatMax] ?: 3,
            onboardingComplete = p[Keys.onboarding] ?: false,
            notificationPrimingShown = p[Keys.priming] ?: false,
            inboxReadSignature = p[Keys.inboxReadSignature] ?: "",
        )
    }

    suspend fun setLocale(pref: LocalePref) = edit { it[Keys.locale] = pref.name }
    suspend fun setTimeFormat(fmt: TimeFormat?) = edit {
        if (fmt == null) it.remove(Keys.timeFormat) else it[Keys.timeFormat] = fmt.name
    }
    suspend fun setBiggerText(v: Boolean) = edit { it[Keys.biggerText] = v }
    suspend fun setReadAloud(v: Boolean) = edit { it[Keys.readAloud] = v }
    suspend fun setFullScreenAlarm(v: Boolean) = edit { it[Keys.fullScreenAlarm] = v }
    suspend fun setAlarmSound(v: String) = edit { it[Keys.alarmSound] = v }
    suspend fun setRepeat(everyMinutes: Int, maxRepeats: Int) = edit {
        it[Keys.repeatEvery] = everyMinutes.coerceIn(1, 60)
        it[Keys.repeatMax] = maxRepeats.coerceIn(0, 10)
    }
    suspend fun setOnboardingComplete(v: Boolean) = edit { it[Keys.onboarding] = v }
    suspend fun setPrimingShown(v: Boolean) = edit { it[Keys.priming] = v }
    suspend fun setInboxReadSignature(v: String) = edit { it[Keys.inboxReadSignature] = v }

    private suspend fun edit(block: (androidx.datastore.preferences.core.MutablePreferences) -> Unit) {
        context.dataStore.edit(block)
    }
}
