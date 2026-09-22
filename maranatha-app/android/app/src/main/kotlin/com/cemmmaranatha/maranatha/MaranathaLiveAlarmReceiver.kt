package com.cemmmaranatha.maranatha

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import androidx.core.content.ContextCompat

class MaranathaLiveAlarmReceiver :
    BroadcastReceiver() {

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {
        if (
            !MaranathaLiveStore
                .enabled(context)
        ) {
            return
        }

        val id =
            intent
                .getStringExtra("id")
                .orEmpty()

        val title =
            intent
                .getStringExtra("title")
                .orEmpty()

        val url =
            intent
                .getStringExtra("url")
                .orEmpty()

        val snooze =
            intent.getBooleanExtra(
                "snooze",
                false
            )

        if (
            id.isBlank() ||
            url.isBlank()
        ) {
            return
        }

        if (
            MaranathaLiveStore
                .dismissed(
                    context,
                    id
                )
        ) {
            return
        }

        if (snooze) {
            MaranathaLiveStore
                .removeSnooze(
                    context,
                    id
                )
        }

        val item =
            MaranathaLiveItem(
                id = id,
                title =
                    title.ifBlank {
                        "Direct MARANATHA"
                    },
                audioUrl = url,
                triggerAtMillis =
                    System.currentTimeMillis()
            )

        val source =
            MaranathaLiveCache
                .resolveSource(
                    context,
                    item
                )

        val service =
            Intent(
                context,
                MaranathaLiveAudioService::class.java
            ).apply {
                action =
                    MaranathaLiveAudioService
                        .ACTION_PLAY

                putExtra(
                    MaranathaLiveAudioService
                        .EXTRA_ID,
                    item.id
                )

                putExtra(
                    MaranathaLiveAudioService
                        .EXTRA_TITLE,
                    item.title
                )

                putExtra(
                    MaranathaLiveAudioService
                        .EXTRA_URL,
                    source
                )

                putExtra(
                    MaranathaLiveAudioService
                        .EXTRA_ORIGINAL_URL,
                    item.audioUrl
                )
            }

        ContextCompat
            .startForegroundService(
                context,
                service
            )
    }
}
