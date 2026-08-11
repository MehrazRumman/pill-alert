package com.nirbhor.app

import android.app.Application
import com.nirbhor.app.data.NirbhorDatabase
import com.nirbhor.app.data.NirbhorRepository
import com.nirbhor.app.data.SettingsStore
import com.nirbhor.app.notifications.NirbhorNotifications
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.LocalDate

/**
 * App entry point. Owns the manual DI container ([AppContainer]) and seeds first-run sample data.
 */
class NirbhorApp : Application() {

    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
        NirbhorNotifications.createChannels(this)

        container.appScope.launch(Dispatchers.IO) {
            // No demo/seed data — the app starts empty and the user adds their own medicines.
            // Generate dose occurrences for the next two weeks from whatever medicines exist,
            // then arm reminders for upcoming doses.
            val today = LocalDate.now()
            for (i in 0..14) container.repository.ensureDosesFor(today.plusDays(i.toLong()))
            com.nirbhor.app.notifications.AlarmScheduler.rescheduleAll(this@NirbhorApp)
        }
    }
}

/** Trivial service locator — the app is small enough that a DI framework would be overkill. */
class AppContainer(app: Application) {
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    val database: NirbhorDatabase = NirbhorDatabase.get(app)
    val repository: NirbhorRepository = NirbhorRepository.get(app)
    val settings: SettingsStore = SettingsStore(app)
}
