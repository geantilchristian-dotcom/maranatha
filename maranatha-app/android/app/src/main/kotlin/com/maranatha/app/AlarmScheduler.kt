package com.maranatha.app
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
object AlarmScheduler {
    const val EXTRA_ID = "alarm_id"
    const val EXTRA_TITLE = "alarm_title"
    const val EXTRA_AUDIO_URL = "alarm_audio_url"
    const val EXTRA_TRIGGER_AT = "alarm_trigger_at"
    private const val ACTION_TRIGGER_PREFIX =
        "com.maranatha.app.ALARM_TRIGGER."
    private const val ACTION_SHOW_PREFIX =
        "com.maranatha.app.ALARM_SHOW."
    private const val RECENT_WINDOW_MS =
        15 * 60 * 1000L
    fun canScheduleExact(
        context: Context
    ): Boolean {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.S
        ) {
            return true
        }
        val alarmManager =
            context.getSystemService(
                Context.ALARM_SERVICE
            ) as? AlarmManager
        return alarmManager
            ?.canScheduleExactAlarms() == true
    }
    fun schedule(
        context: Context,
        alarm: SermonAlarm,
        persist: Boolean = true
    ): Boolean {
        if (persist) {
            AlarmStore.save(
                context,
                alarm
            )
        }
        AudioCache.prepare(
            context,
            alarm
        )
        if (
            !AlarmStore.isModeEnabled(context)
        ) {
            return false
        }
        val alarmManager =
            context.getSystemService(
                Context.ALARM_SERVICE
            ) as? AlarmManager
                ?: return false
        val triggerAt =
            maxOf(
                alarm.triggerAtMillis,
                System.currentTimeMillis() + 1000L
            )
        val triggerIntent =
            triggerPendingIntent(
                context,
                alarm
            )
        val showIntent =
            showPendingIntent(
                context,
                alarm
            )
        val exact =
            canScheduleExact(context)
        return try {
            if (exact) {
                alarmManager.setAlarmClock(
                    AlarmManager.AlarmClockInfo(
                        triggerAt,
                        showIntent
                    ),
                    triggerIntent
                )
            } else {
                alarmManager.setAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    triggerAt,
                    triggerIntent
                )
            }
            exact
        } catch (
            _error: SecurityException
        ) {
            alarmManager.setAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                triggerAt,
                triggerIntent
            )
            false
        }
    }
    fun cancel(
        context: Context,
        id: String,
        removeFromStore: Boolean = true
    ) {
        val alarmManager =
            context.getSystemService(
                Context.ALARM_SERVICE
            ) as? AlarmManager
        val intent =
            Intent(
                context,
                AlarmReceiver::class.java
            ).apply {
                action =
                    ACTION_TRIGGER_PREFIX + id
            }
        val pendingIntent =
            PendingIntent.getBroadcast(
                context,
                requestCode(id),
                intent,
                PendingIntent.FLAG_NO_CREATE or
                    PendingIntent.FLAG_IMMUTABLE
            )
        if (pendingIntent != null) {
            alarmManager?.cancel(
                pendingIntent
            )
            pendingIntent.cancel()
        }
        if (removeFromStore) {
            AlarmStore.remove(
                context,
                id
            )
            AudioCache.remove(
                context,
                id
            )
        }
    }
    fun cancelAll(
        context: Context
    ) {
        AlarmStore
            .getAll(context)
            .forEach {
                cancel(
                    context,
                    it.id,
                    false
                )
            }
    }
    fun rescheduleAll(
        context: Context
    ) {
        if (
            !AlarmStore.isModeEnabled(context)
        ) {
            return
        }
        val now =
            System.currentTimeMillis()
        val all =
            AlarmStore.getAll(context)
        val future =
            all.filter {
                it.triggerAtMillis > now
            }
        all
            .filter {
                it.triggerAtMillis <= now
            }
            .forEach {
                AlarmStore.remove(
                    context,
                    it.id
                )
                AudioCache.remove(
                    context,
                    it.id
                )
            }
        future.forEach {
            schedule(
                context,
                it,
                false
            )
        }
    }
    fun syncServerAlarms(
        context: Context,
        serverAlarms: List<SermonAlarm>
    ) {
        val now =
            System.currentTimeMillis()
        val future =
            serverAlarms.filter {
                it.triggerAtMillis > now
            }
        val recent =
            serverAlarms
                .filter {
                    it.triggerAtMillis <= now &&
                        now - it.triggerAtMillis <=
                        RECENT_WINDOW_MS
                }
                .maxByOrNull {
                    it.triggerAtMillis
                }
        val existing =
            AlarmStore
                .getAll(context)
                .filterNot {
                    it.id.startsWith(
                        "snooze:"
                    )
                }
                .associateBy {
                    it.id
                }
        val incomingIds =
            (
                future.map { it.id } +
                    listOfNotNull(
                        recent?.id
                    )
                ).toSet()
        existing.keys
            .filterNot {
                incomingIds.contains(it)
            }
            .forEach { id ->
                cancel(
                    context,
                    id,
                    false
                )
                AlarmStore.remove(
                    context,
                    id
                )
                AudioCache.remove(
                    context,
                    id
                )
            }
        AlarmStore.replaceServerAlarms(
            context,
            future
        )
        if (
            AlarmStore.isModeEnabled(context)
        ) {
            future.forEach {
                schedule(
                    context,
                    it,
                    false
                )
            }
            if (recent != null) {
                AlarmLauncher.start(
                    context,
                    recent
                )
            }
        }
    }
    fun scheduleSnooze(
        context: Context,
        source: SermonAlarm,
        minutes: Int = 5
    ) {
        val triggerAt =
            System.currentTimeMillis() +
                minutes * 60_000L
        val alarm =
            source.copy(
                id =
                    "snooze:${source.id}:$triggerAt",
                triggerAtMillis =
                    triggerAt
            )
        schedule(
            context,
            alarm
        )
    }
    private fun triggerPendingIntent(
        context: Context,
        alarm: SermonAlarm
    ): PendingIntent {
        val intent =
            Intent(
                context,
                AlarmReceiver::class.java
            ).apply {
                action =
                    ACTION_TRIGGER_PREFIX +
                    alarm.id
                with(AlarmScheduler) {
                    putAlarm(alarm)
                }
            }
        return PendingIntent.getBroadcast(
            context,
            requestCode(alarm.id),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )
    }
    private fun showPendingIntent(
        context: Context,
        alarm: SermonAlarm
    ): PendingIntent {
        val intent =
            Intent(
                context,
                AlarmActivity::class.java
            ).apply {
                action =
                    ACTION_SHOW_PREFIX +
                    alarm.id
                flags =
                    Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
                with(AlarmScheduler) {
                    putAlarm(alarm)
                }
            }
        return PendingIntent.getActivity(
            context,
            requestCode(alarm.id) xor 20905,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or
                PendingIntent.FLAG_IMMUTABLE
        )
    }
    fun Intent.putAlarm(
        alarm: SermonAlarm
    ): Intent {
        putExtra(
            EXTRA_ID,
            alarm.id
        )
        putExtra(
            EXTRA_TITLE,
            alarm.title
        )
        putExtra(
            EXTRA_AUDIO_URL,
            alarm.audioUrl
        )
        putExtra(
            EXTRA_TRIGGER_AT,
            alarm.triggerAtMillis
        )
        return this
    }
    fun Intent.readAlarm():
        SermonAlarm? {
        val id =
            getStringExtra(
                EXTRA_ID
            )?.trim().orEmpty()
        val title =
            getStringExtra(
                EXTRA_TITLE
            )?.trim().orEmpty()
        val audioUrl =
            getStringExtra(
                EXTRA_AUDIO_URL
            )?.trim().orEmpty()
        val triggerAt =
            getLongExtra(
                EXTRA_TRIGGER_AT,
                0L
            )
        if (
            id.isBlank() ||
            audioUrl.isBlank()
        ) {
            return null
        }
        return SermonAlarm(
            id = id,
            title =
                title.ifBlank {
                    "Prédication Maranatha"
                },
            audioUrl = audioUrl,
            triggerAtMillis = triggerAt
        )
    }
    private fun requestCode(
        id: String
    ): Int {
        return id.hashCode() and
            Int.MAX_VALUE
    }
}