package com.nirbhor.app.notifications

import android.app.Notification
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.app.NotificationCompat
import com.nirbhor.app.R

/**
 * Fires at a dose time. Posts a high-importance notification with a full-screen intent so the
 * [AlarmActivity] shows over the lock screen (README > Full-screen alarm).
 */
class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val doseId = intent.getLongExtra(AlarmScheduler.EXTRA_DOSE_ID, -1L)
        val epoch = intent.getLongExtra(AlarmScheduler.EXTRA_EPOCH, System.currentTimeMillis())

        val fullScreen = Intent(context, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra(AlarmScheduler.EXTRA_DOSE_ID, doseId)
            putExtra(AlarmScheduler.EXTRA_EPOCH, epoch)
        }
        val fsPi = PendingIntent.getActivity(
            context, doseId.toInt(), fullScreen,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification: Notification = NotificationCompat.Builder(context, NirbhorNotifications.CHANNEL_REMINDERS)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setContentTitle("ওষুধ খাওয়ার সময়")
            .setContentText("নির্ভর মনে করিয়ে দিচ্ছে")
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fsPi, true)
            .setContentIntent(fsPi)
            .setAutoCancel(true)
            .setOngoing(true)
            .build()

        val nm = context.getSystemService(NotificationManager::class.java)
        nm?.notify(doseId.toInt(), notification)
    }
}
