package com.maranatha.app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

class MaranathaMessagingService : FirebaseMessagingService() {
    companion object {
        private const val TYPE_PROGRAMMER = "PROGRAMMER_PREDICATION"
        private const val TYPE_ANNULER = "ANNULER_PREDICATION"
        private const val TYPE_DEMARRER = "DEMARRER_PREDICATION"
        private const val TYPE_ARRETER = "ARRETER_PREDICATION"
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
