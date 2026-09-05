package com.maranatha.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (!AlarmStore.isModeEnabled(context)) {
            return
        }

        val alarm = with(AlarmScheduler) { intent.readAlarm() }
            ?: intent.getStringExtra(AlarmScheduler.EXTRA_ID)?.let { id ->
                AlarmStore.get(context, id)
            }
            ?: return

        AlarmStore.remove(context, alarm.id)
        AlarmLauncher.start(context, alarm)
    }
}

class AlarmActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarm = with(AlarmScheduler) { intent.readAlarm() }

        when (intent.action) {
            MaranathaAlarmService.ACTION_SNOOZE -> {
                if (alarm != null) {
                    AlarmScheduler.scheduleSnooze(context, alarm)
                }
                AlarmLauncher.stop(context)
            }

            MaranathaAlarmService.ACTION_STOP -> {
                AlarmLauncher.stop(context)
            }
        }
    }
}

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            "android.app.action.SCHEDULE_EXACT_ALARM_PERMISSION_STATE_CHANGED" -> {
                AlarmScheduler.rescheduleAll(context)
            }
        }
    }
}

object AlarmLauncher {
    fun start(context: Context, alarm: SermonAlarm) {
        val intent = Intent(context, MaranathaAlarmService::class.java).apply {
            action = MaranathaAlarmService.ACTION_START
            with(AlarmScheduler) { putAlarm(alarm) }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            context.startForegroundService(intent)
        } else {
            context.startService(intent)
        }
    }

    fun stop(context: Context) {
        context.stopService(
            Intent(context, MaranathaAlarmService::class.java),
        )
    }
}


