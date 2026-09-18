package com.maranatha.app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build

class MaranathaMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TYPE_PROGRAMMER = "PROGRAMMER_PREDICATION"
        private const val TYPE_ANNULER = "ANNULER_PREDICATION"
        private const val TYPE_DEMARRER = "DEMARRER_PREDICATION"
        private const val TYPE_ARRETER = "ARRETER_PREDICATION"
        private const val TYPE_PUBLICATION = "PUBLICATION_NOUVELLE"
    }

    override fun onNewToken(token: String) {
        super.onNewToken(token)
        AlarmStore.saveFcmToken(this, token)
    }

    override fun onMessageReceived(message: RemoteMessage) {
        super.onMessageReceived(message)

        val data = message.data
        val type = data["type"].orEmpty()
        val id = data["sermon_id"].orEmpty().trim()

        when (type) {
            TYPE_PUBLICATION -> {
                PublicationNotification.show(this, data)
            }
            TYPE_PROGRAMMER -> {
                val alarm = parseAlarm(data) ?: return
                AlarmStore.save(this, alarm)

                if (!AlarmStore.isModeEnabled(this)) {
                    return
                }

                val now = System.currentTimeMillis()
                if (alarm.triggerAtMillis > now) {
                    AlarmScheduler.schedule(this, alarm, persist = false)
                    ScheduleNotification.show(this, alarm)
                } else if (now - alarm.triggerAtMillis <= 15 * 60 * 1000L) {
                    AlarmLauncher.start(this, alarm)
                }
            }

            TYPE_ANNULER -> {
                if (id.isNotEmpty()) {
                    AlarmScheduler.cancel(this, id)
                    ScheduleNotification.cancel(this, id)
                }
            }

            TYPE_DEMARRER -> {
                val alarm = parseAlarm(data) ?: return
                if (AlarmStore.isModeEnabled(this)) {
                    AlarmScheduler.cancel(this, alarm.id, removeFromStore = false)
                    AlarmStore.remove(this, alarm.id)
                    ScheduleNotification.cancel(this, alarm.id)
                    AlarmLauncher.start(this, alarm)
                }
            }

            TYPE_ARRETER -> {
                if (id.isNotEmpty()) {
                    AlarmScheduler.cancel(this, id)
                    ScheduleNotification.cancel(this, id)
                }
                AlarmLauncher.stop(this)
            }
        }
    }

    private fun parseAlarm(data: Map<String, String>): SermonAlarm? {
        val id = data["sermon_id"].orEmpty().trim()
        val title = data["sermon_titre"].orEmpty().trim()
        val audioUrl = data["audio_url"].orEmpty().trim()
        val triggerAt = data["scheduled_at_ms"]?.toLongOrNull() ?: 0L

        if (id.isEmpty() || audioUrl.isEmpty()) {
            return null
        }

        return SermonAlarm(
            id = id,
            title = title.ifEmpty { "Prédication Maranatha" },
            audioUrl = audioUrl,
            triggerAtMillis = triggerAt.coerceAtLeast(System.currentTimeMillis()),
        )
    }
}

private object PublicationNotification {
    private const val CHANNEL_ID = "maranatha_publications"

    fun show(context: Context, data: Map<String, String>) {
        val path = data["publication_path"]?.trim().orEmpty()
        if (!isSafePath(path)) return
        val title = data["title"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: data["notification_title"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: data["publication_title"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: "Nouvelle publication"
        val body = data["body"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: data["notification_body"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: data["publication_body"]?.trim().takeUnless { it.isNullOrEmpty() }
            ?: "Découvrez la nouvelle publication de Maranatha."
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE)
            as? NotificationManager ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Publications Maranatha",
                    NotificationManager.IMPORTANCE_HIGH,
                ).apply { description = "Nouvelles publications Maranatha" },
            )
        }
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra(MainActivity.EXTRA_PUBLICATION_PATH, path)
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            path.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(context, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(context)
        }
        manager.notify(path.hashCode(), builder
            .setSmallIcon(R.drawable.ic_notification)
            .setColor(context.getColor(R.color.maranatha_gold))
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(Notification.BigTextStyle().bigText(body))
            .setContentIntent(pendingIntent)
            .setCategory(Notification.CATEGORY_MESSAGE)
            .setAutoCancel(true)
            .build())
    }

    private fun isSafePath(path: String): Boolean {
        return path.startsWith("/") && !path.startsWith("//") &&
            !path.contains('\\') && !path.contains('\u0000') &&
            !path.contains("://") && UriPathParser.isSafe(path)
    }
}

private object UriPathParser {
    fun isSafe(path: String): Boolean = try {
        val uri = android.net.Uri.parse(path)
        uri.scheme == null && uri.host == null
    } catch (_: Exception) {
        false
    }
}
