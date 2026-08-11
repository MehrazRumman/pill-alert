package com.nirbhor.app.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nirbhor.app.data.NirbhorRepository
import java.time.LocalDate

/**
 * Schedules exact alarms for upcoming doses (README > Alarms: full-screen intent at each dose time).
 * We schedule every upcoming dose in the next 48h as its own exact alarm keyed by dose id, and
 * re-run this after any change (dose taken, medicine added, boot).
 */
object AlarmScheduler {

    const val EXTRA_DOSE_ID = "dose_id"
    const val EXTRA_EPOCH = "dose_epoch"
    const val EXTRA_REPEAT_COUNT = "repeat_count"
    private const val ACTION_ALARM = "com.nirbhor.app.ACTION_ALARM"
    private const val SCHEDULE_DAYS = 15

    fun pendingIntent(context: Context, doseId: Long, epoch: Long, repeatCount: Int = 0): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_ALARM
            putExtra(EXTRA_DOSE_ID, doseId)
            putExtra(EXTRA_EPOCH, epoch)
            putExtra(EXTRA_REPEAT_COUNT, repeatCount)
        }
        return PendingIntent.getBroadcast(
            context, doseId.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    fun scheduleRepeat(context: Context, doseId: Long, epoch: Long, repeatCount: Int) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val pi = pendingIntent(context, doseId, epoch, repeatCount)
        schedule(am, epoch, pi)
    }

    /** Reschedules alarms for all upcoming doses. Safe to call often. */
    suspend fun rescheduleAll(context: Context) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val repo = NirbhorRepository.get(context)
        val today = LocalDate.now()
        for (offset in 0 until SCHEDULE_DAYS) {
            repo.ensureDosesFor(today.plusDays(offset.toLong()))
        }
        val doses = repo.upcomingDoses(SCHEDULE_DAYS * 24L * 60L * 60_000L)
        for (dose in doses) {
            val pi = pendingIntent(context, dose.id, dose.scheduledEpochMillis)
            schedule(am, dose.scheduledEpochMillis, pi)
        }
    }

    private fun schedule(am: AlarmManager, epoch: Long, pi: PendingIntent) {
        val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
        try {
            if (canExact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epoch, pi)
            } else {
                // Still wake the device when exact-alarm access is unavailable. Android chooses
                // the nearest battery-friendly delivery time.
                am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epoch, pi)
            }
        } catch (_: SecurityException) {
            // Access can be revoked between canScheduleExactAlarms() and this call.
            am.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, epoch, pi)
        }
    }

    fun cancel(context: Context, doseId: Long) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        am.cancel(pendingIntent(context, doseId, 0))
    }
}
