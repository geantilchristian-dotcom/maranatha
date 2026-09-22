package com.cemmmaranatha.maranatha

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.content.ContextCompat

object MaranathaLiveScheduler {
    private const val LATE_WINDOW =
        15 * 60 * 1000L

    fun sync(
        context: Context,
        raw: List<*>
    ): Int {
        val items =
            raw.mapNotNull {
                val map =
                    it as? Map<*, *>
                        ?: return@mapNotNull null

                MaranathaLiveItem
                    .fromMap(map)
            }

        val oldItems =
            MaranathaLiveStore
                .read(context)

        val newIds =
            items.map { it.id }.toSet()

        oldItems
            .filter { it.id !in newIds }
            .forEach {
                cancel(
                    context,
                    it,
                    false
                )
            }

        MaranathaLiveStore.save(
            context,
            items
        )

        items.forEach {
            schedule(
                context,
                it,
                false
            )
        }

        MaranathaLiveCache
            .prefetchAsync(
                context,
                items
            )

        return items.size
    }

    fun schedule(
        context: Context,
        item: MaranathaLiveItem,
        snooze: Boolean = false
    ) {
        if (
            !MaranathaLiveStore
                .enabled(context)
        ) {
            return
        }

        if (
            MaranathaLiveStore
                .dismissed(
                    context,
                    item.id
                )
        ) {
            return
        }

        val now =
            System.currentTimeMillis()

        if (
            item.triggerAtMillis <= now
        ) {
            if (
                item.triggerAtMillis >=
                now - LATE_WINDOW
            ) {
                startImmediately(
                    context,
                    item
                )
            }

            return
        }

        val manager =
            context.getSystemService(
                AlarmManager::class.java
            )
                ?: return

        val pending =
            pendingIntent(
                context,
                item,
                snooze
            )

        try {
            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.S &&
                !manager
                    .canScheduleExactAlarms()
            ) {
                manager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    item.triggerAtMillis,
                    pending
                )
            } else {
                manager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    item.triggerAtMillis,
                    pending
                )
            }
        } catch (_error: Exception) {
            manager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                item.triggerAtMillis,
                pending
            )
        }
    }

    fun snooze(
        context: Context,
        item: MaranathaLiveItem,
        minutes: Int = 10
    ) {
        val snoozed =
            item.copy(
                triggerAtMillis =
                    System.currentTimeMillis() +
                    minutes * 60_000L
            )

        MaranathaLiveStore
            .saveSnooze(
                context,
                snoozed
            )

        schedule(
            context,
            snoozed,
            true
        )
    }

    fun rescheduleAll(
        context: Context
    ) {
        MaranathaLiveStore
            .read(context)
            .forEach {
                schedule(
                    context,
                    it,
                    false
                )
            }

        val now =
            System.currentTimeMillis()

        MaranathaLiveStore
            .readSnoozes(context)
            .forEach {
                if (
                    it.triggerAtMillis <
                    now - LATE_WINDOW
                ) {
                    MaranathaLiveStore
                        .removeSnooze(
                            context,
                            it.id
                        )
                } else {
                    schedule(
                        context,
                        it,
                        true
                    )
                }
            }

        MaranathaLiveCache
            .prefetchAsync(
                context,
                MaranathaLiveStore
                    .read(context)
            )
    }

    fun canScheduleExact(
        context: Context
    ): Boolean {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.S
        ) {
            return true
        }

        return context
            .getSystemService(
                AlarmManager::class.java
            )
            ?.canScheduleExactAlarms() ==
            true
    }

    private fun cancel(
        context: Context,
        item: MaranathaLiveItem,
        snooze: Boolean
    ) {
        val manager =
            context.getSystemService(
                AlarmManager::class.java
            )
                ?: return

        val pending =
            pendingIntent(
                context,
                item,
                snooze
            )

        manager.cancel(pending)
        pending.cancel()
    }

    private fun pendingIntent(
        context: Context,
        item: MaranathaLiveItem,
        snooze: Boolean
    ): PendingIntent {
        val key =
            if (snooze) {
                "${item.id}:snooze"
            } else {
                item.id
            }

        return PendingIntent.getBroadcast(
            context,
            key.hashCode() and
                0x7FFFFFFF,
            Intent(
                context,
                MaranathaLiveAlarmReceiver::class.java
            ).apply {
                action =
                    if (snooze) {
                        "maranatha.live.snooze.${item.id}"
                    } else {
                        "maranatha.live.${item.id}"
                    }

                putExtra("id", item.id)
                putExtra(
                    "title",
                    item.title
                )
                putExtra(
                    "url",
                    item.audioUrl
                )
                putExtra(
                    "snooze",
                    snooze
                )
            },
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun startImmediately(
        context: Context,
        item: MaranathaLiveItem
    ) {
        if (
            MaranathaLiveStore
                .dismissed(
                    context,
                    item.id
                )
        ) {
            return
        }

        val source =
            MaranathaLiveCache
                .resolveSource(
                    context,
                    item
                )

        val intent =
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
                intent
            )
    }
}
