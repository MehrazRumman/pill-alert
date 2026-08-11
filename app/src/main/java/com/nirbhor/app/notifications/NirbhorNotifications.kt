package com.nirbhor.app.notifications

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context

/** Notification channels. Reminders is high-importance (full-screen intent over the lock screen). */
object NirbhorNotifications {
    const val CHANNEL_REMINDERS = "reminders"
    const val CHANNEL_STOCK = "low_stock"
    const val CHANNEL_CAREGIVER = "caregiver"

    fun createChannels(context: Context) {
        val nm = context.getSystemService(NotificationManager::class.java) ?: return

        val reminders = NotificationChannel(
            CHANNEL_REMINDERS,
            "মনে করিয়ে দেওয়া",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "ওষুধ খাওয়ার সময় হলে জানানো হয়"
            enableVibration(true)
        }
        val stock = NotificationChannel(
            CHANNEL_STOCK,
            "ওষুধ ফুরিয়ে আসা",
            NotificationManager.IMPORTANCE_DEFAULT,
        ).apply { description = "ওষুধ কমে গেলে জানানো হয়" }
        val caregiver = NotificationChannel(
            CHANNEL_CAREGIVER,
            "পরিবারকে জানানো",
            NotificationManager.IMPORTANCE_DEFAULT,
        )
        nm.createNotificationChannel(reminders)
        nm.createNotificationChannel(stock)
        nm.createNotificationChannel(caregiver)
    }
}
