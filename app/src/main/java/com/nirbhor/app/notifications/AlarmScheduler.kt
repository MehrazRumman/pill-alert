package com.nirbhor.app.notifications

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import com.nirbhor.app.data.NirbhorRepository

/**
 * Schedules exact alarms for upcoming doses (README > Alarms: full-screen intent at each dose time).
 * We schedule every upcoming dose in the next 48h as its own exact alarm keyed by dose id, and
 * re-run this after any change (dose taken, medicine added, boot).
 */
object AlarmScheduler {

    const val EXTRA_DOSE_ID = "dose_id"
    const val EXTRA_EPOCH = "dose_epoch"
    private const val ACTION_ALARM = "com.nirbhor.app.ACTION_ALARM"

    fun pendingIntent(context: Context, doseId: Long, epoch: Long): PendingIntent {
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            action = ACTION_ALARM
            putExtra(EXTRA_DOSE_ID, doseId)
            putExtra(EXTRA_EPOCH, epoch)
        }
        return PendingIntent.getBroadcast(
            context, doseId.toInt(), intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    /** Reschedules alarms for all upcoming doses. Safe to call often. */
    suspend fun rescheduleAll(context: Context) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        val repo = NirbhorRepository.get(context)
        val doses = repo.upcomingDoses()
        for (dose in doses) {
            val pi = pendingIntent(context, dose.id, dose.scheduledEpochMillis)
            val canExact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || am.canScheduleExactAlarms()
            if (canExact) {
                am.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, dose.scheduledEpochMillis, pi)
            } else {
                // Fall back to an inexact window if the user hasn't granted exact-alarm permission.
                am.setWindow(AlarmManager.RTC_WAKEUP, dose.scheduledEpochMillis, 10 * 60_000L, pi)
            }
        }
    }

    fun cancel(context: Context, doseId: Long) {
        val am = context.getSystemService(AlarmManager::class.java) ?: return
        am.cancel(pendingIntent(context, doseId, 0))
    }
}
