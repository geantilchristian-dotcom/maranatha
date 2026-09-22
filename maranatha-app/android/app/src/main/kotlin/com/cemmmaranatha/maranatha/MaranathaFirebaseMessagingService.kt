package com.cemmmaranatha.maranatha
import android.content.Intent
import android.util.Log
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage
class MaranathaFirebaseMessagingService :
    FirebaseMessagingService() {
    override fun onNewToken(
        token: String
    ) {
        super.onNewToken(token)
        MaranathaFirebaseRegistrar
            .registerToken(
                this,
                token
            )
    }
    override fun onMessageReceived(
        message: RemoteMessage
    ) {
        super.onMessageReceived(message)
        val data =
            message.data
        val type =
            data["type"]
                ?.trim()
                ?.uppercase()
                .orEmpty()
        Log.i(
            "MARANATHA-FCM",
            "Message recu : $type"
        )
        when (type) {
            "PROGRAMMER_PREDICATION" ->
                programmer(data)
            "ANNULER_PREDICATION" ->
                annuler(data)
            "DEMARRER_PREDICATION" ->
                demarrer(data)
            "ARRETER_PREDICATION" ->
                arreter(data)
        }
    }
    private fun programmer(
        data: Map<String, String>
    ) {
        val id =
            data["sermon_id"]
                ?.trim()
                .orEmpty()
        val title =
            data["sermon_titre"]
                ?.trim()
                .orEmpty()
        val audioUrl =
            data["audio_url"]
                ?.trim()
                .orEmpty()
        val trigger =
            data["scheduled_at_ms"]
                ?.toLongOrNull()
                ?: return
        if (
            id.isBlank() ||
            audioUrl.isBlank()
        ) {
            return
        }
        MaranathaLiveStore
            .clearDismissed(
                this,
                id
            )
        val item =
            MaranathaLiveItem(
                id = id,
                title =
                    title.ifBlank {
                        "MARANATHA"
                    },
                audioUrl =
                    audioUrl,
                triggerAtMillis =
                    trigger
            )
        val items =
            MaranathaLiveStore
                .read(this)
                .filterNot {
                    it.id == id
                }
                .toMutableList()
        items.add(item)
        synchroniser(items)
        Log.i(
            "MARANATHA-FCM",
            "Predication programmee : $id"
        )
    }
    private fun annuler(
        data: Map<String, String>
    ) {
        val id =
            data["sermon_id"]
                ?.trim()
                .orEmpty()
        if (id.isBlank()) {
            return
        }
        val remaining =
            MaranathaLiveStore
                .read(this)
                .filterNot {
                    it.id == id
                }
        synchroniser(
            remaining
        )
        MaranathaLiveStore
            .removeSnooze(
                this,
                id
            )
        Log.i(
            "MARANATHA-FCM",
            "Predication annulee : $id"
        )
    }
    private fun demarrer(
        data: Map<String, String>
    ) {
        val id =
            data["sermon_id"]
                ?.trim()
                .orEmpty()
        val title =
            data["sermon_titre"]
                ?.trim()
                .orEmpty()
        val audioUrl =
            data["audio_url"]
                ?.trim()
                .orEmpty()
        if (
            id.isBlank() ||
            audioUrl.isBlank()
        ) {
            return
        }
        MaranathaLiveStore
            .clearDismissed(
                this,
                id
            )
        val item =
            MaranathaLiveItem(
                id = id,
                title =
                    title.ifBlank {
                        "MARANATHA"
                    },
                audioUrl =
                    audioUrl,
                triggerAtMillis =
                    System.currentTimeMillis()
            )
        MaranathaLiveScheduler
            .schedule(
                this,
                item
            )
        Log.i(
            "MARANATHA-FCM",
            "Demarrage immediat : $id"
        )
    }
    private fun arreter(
        data: Map<String, String>
    ) {
        val id =
            data["sermon_id"]
                ?.trim()
                .orEmpty()
        if (id.isNotBlank()) {
            val remaining =
                MaranathaLiveStore
                    .read(this)
                    .filterNot {
                        it.id == id
                    }
            synchroniser(
                remaining
            )
        }
        val stopIntent =
            Intent(
                this,
                MaranathaLiveAudioService::class.java
            ).apply {
                action =
                    MaranathaLiveAudioService
                        .ACTION_STOP
            }
        try {
            startService(
                stopIntent
            )
        } catch (
            error: Exception
        ) {
            Log.e(
                "MARANATHA-FCM",
                "Arret service impossible",
                error
            )
        }
    }
    private fun synchroniser(
        items: List<MaranathaLiveItem>
    ) {
        val raw =
            items.map { item ->
                mapOf(
                    "id" to
                        item.id,
                    "title" to
                        item.title,
                    "audioUrl" to
                        item.audioUrl,
                    "triggerAtMillis" to
                        item.triggerAtMillis
                )
            }
        MaranathaLiveScheduler
            .sync(
                this,
                raw
            )
    }
}
