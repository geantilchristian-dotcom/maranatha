package com.maranatha.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import java.text.DateFormat
import java.util.Date

object ScheduleNotification {
    private const val CHANNEL_ID = "maranatha_programmations"

    fun show(context: Context, alarm: SermonAlarm) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            ?: return

        createChannel(manager)

        val openIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val openPendingIntent = PendingIntent.getActivity(
            context,
            notificationId(alarm.id),
            openIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val dateLabel = DateFormat.getDateTimeInstance(
            DateFormat.MEDIUM,
            DateFormat.SHORT,
        ).format(Date(alarm.triggerAtMillis))

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }

        val notification = builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle("Réveil Maranatha programmé")
            .setContentText("${alarm.title} • $dateLabel")
            .setStyle(
                Notification.BigTextStyle()
                    .bigText("${alarm.title}\nDéclenchement automatique : $dateLabel"),
            )
            .setContentIntent(openPendingIntent)
            .setCategory(Notification.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setOnlyAlertOnce(true)
            .build()

        manager.notify(notificationId(alarm.id), notification)
    }

    fun cancel(context: Context, id: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.cancel(notificationId(id))
    }

    private fun createChannel(manager: NotificationManager) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Programmations Maranatha",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Confirmation des prédications programmées"
            setSound(null, null)
            enableVibration(false)
        }
        manager.createNotificationChannel(channel)
    }

    private fun notificationId(id: String): Int {
        return (id.hashCode() xor 0x4D41) and 0x7fffffff
    }
}
