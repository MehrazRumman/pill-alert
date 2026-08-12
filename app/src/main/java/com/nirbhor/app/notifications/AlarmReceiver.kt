package com.nirbhor.app.notifications

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.nirbhor.app.R
import com.nirbhor.app.data.NirbhorRepository
import com.nirbhor.app.data.SettingsStore
import com.nirbhor.app.domain.DoseStatus
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.first

/**
 * Fires at a dose time. Posts a high-importance notification with a full-screen intent so the
 * [AlarmActivity] shows over the lock screen (README > Full-screen alarm).
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val doseId = intent.getLongExtra(AlarmScheduler.EXTRA_DOSE_ID, -1L)
        val epoch = intent.getLongExtra(AlarmScheduler.EXTRA_EPOCH, System.currentTimeMillis())
        val repeatCount = intent.getIntExtra(AlarmScheduler.EXTRA_REPEAT_COUNT, 0)
        if (doseId < 0L) return

        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val dose = NirbhorRepository.get(context).doseWithMedicine(doseId)
                if (dose == null || dose.dose.status != DoseStatus.UPCOMING) return@launch
                val settings = SettingsStore(context.applicationContext).settings.first()
                val fullScreenAllowed = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                    context.getSystemService(NotificationManager::class.java)?.canUseFullScreenIntent() == true
                } else {
                    true
                }
                postNotification(context, doseId, epoch, settings.fullScreenAlarm && fullScreenAllowed)
                // Refresh the rolling horizon before arming the repeat. Both use the same
                // PendingIntent identity, so the repeat must be the final scheduled alarm.
                AlarmScheduler.rescheduleAll(context.applicationContext)
                if (repeatCount < settings.repeatMax) {
                    val repeatEpoch = System.currentTimeMillis() + settings.repeatEveryMinutes * 60_000L
                    AlarmScheduler.scheduleRepeat(context, doseId, repeatEpoch, repeatCount + 1)
                }
            } finally {
                pendingResult.finish()
            }
        }
    }

    private fun postNotification(context: Context, doseId: Long, epoch: Long, fullScreenEnabled: Boolean) {
        val fullScreen = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra(AlarmScheduler.EXTRA_DOSE_ID, doseId)
            putExtra(AlarmScheduler.EXTRA_EPOCH, epoch)
        }
        val fsPi = PendingIntent.getActivity(
            context, doseId.toInt(), fullScreen,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val builder = NotificationCompat.Builder(context, NirbhorNotifications.CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("ওষুধ খাওয়ার সময়")
            .setContentText("নির্ভর মনে করিয়ে দিচ্ছে")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setContentIntent(fsPi)
            .setAutoCancel(true)
            .setOngoing(true)
        if (fullScreenEnabled) builder.setFullScreenIntent(fsPi, true)
        val notification: Notification = builder.build()

        val nm = context.getSystemService(NotificationManager::class.java)
        try {
            nm?.notify(doseId.toInt(), notification)
        } catch (_: SecurityException) {
            // Android 13+ can revoke notification permission at any time.
        }
    }
}
