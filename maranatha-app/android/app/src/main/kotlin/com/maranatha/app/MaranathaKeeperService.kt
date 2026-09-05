package com.maranatha.app
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.util.Log
import androidx.core.app.NotificationCompat
import kotlin.math.max
class MaranathaKeeperService : Service() {
    companion object {
        private const val ACTION_WATCH =
            "com.maranatha.app.KEEPER_WATCH"
        private const val CHANNEL_ID =
            "maranatha_programmation_active"
        private const val NOTIFICATION_ID = 5103
        private const val WAKE_WINDOW_MS = 600_000L
        private const val WAKE_GRACE_MS = 120_000L
        private const val TAG = "MaranathaKeeper"
        fun sync(
            context: Context,
            alarms: List<SermonAlarm>
        ) {
            val now = System.currentTimeMillis()
            val next = alarms
                .filter { it.triggerAtMillis > now }
                .minByOrNull { it.triggerAtMillis }
            if (
                next == null ||
                !AlarmStore.isModeEnabled(context)
            ) {
                context.stopService(
                    Intent(
                        context,
                        MaranathaKeeperService::class.java
                    )
                )
                return
            }
            val intent =
                Intent(
                    context,
                    MaranathaKeeperService::class.java
                ).apply {
                    action = ACTION_WATCH
                }
            with(AlarmScheduler) { intent.putAlarm(next) }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }
    private val handler =
        Handler(Looper.getMainLooper())
    private var watchedAlarm: SermonAlarm? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private val triggerRunnable = object : Runnable {
        override fun run() {
            val alarm = watchedAlarm ?: return
            val remaining =
                alarm.triggerAtMillis -
                    System.currentTimeMillis()
            if (remaining > 0L) {
                scheduleCheck(remaining)
                return
            }
            Log.i(
                TAG,
                "Keeper trigger id=${alarm.id} at=${System.currentTimeMillis()}"
            )
            AlarmStore.remove(
                applicationContext,
                alarm.id
            )
            AlarmLauncher.start(
                applicationContext,
                alarm
            )
            releaseWakeLock()
            watchedAlarm = null
            stopForegroundCompat()
            stopSelf()
        }
    }
    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        enterForegroundImmediately()
    }
    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        val alarm: SermonAlarm? =
            if (intent?.action != ACTION_WATCH) {
                AlarmStore
                    .getAll(this)
                    .filter {
                        it.triggerAtMillis >
                            System.currentTimeMillis()
                    }
                    .minByOrNull {
                        it.triggerAtMillis
                    }
            } else {
                with(AlarmScheduler) { intent.readAlarm() }
            }
        if (
            alarm == null ||
            !AlarmStore.isModeEnabled(this)
        ) {
            releaseWakeLock()
            stopForegroundCompat()
            stopSelf()
            return START_NOT_STICKY
        }
        watchedAlarm = alarm
        updateNotification(alarm)
        handler.removeCallbacks(triggerRunnable)
        val remaining =
            alarm.triggerAtMillis -
                System.currentTimeMillis()
        if (remaining <= WAKE_WINDOW_MS) {
            acquireWakeLock(
                max(remaining, 0L) +
                    WAKE_GRACE_MS
            )
        }
        scheduleCheck(remaining)
        return START_STICKY
    }
    private fun scheduleCheck(
        remainingWallMs: Long
    ) {
        val targetElapsed =
            SystemClock.elapsedRealtime() +
                max(remainingWallMs, 0L)
        handler.postAtTime(
            triggerRunnable,
            targetElapsed
        )
    }
    private fun acquireWakeLock(
        timeoutMs: Long
    ) {
        if (wakeLock?.isHeld == true) {
            return
        }
        val manager =
            getSystemService(Context.POWER_SERVICE)
                as PowerManager
        wakeLock =
            manager.newWakeLock(
                PowerManager.PARTIAL_WAKE_LOCK,
                "Maranatha:KeeperWakeLock"
            ).apply {
                setReferenceCounted(false)
                acquire(
                    timeoutMs.coerceIn(
                        WAKE_GRACE_MS,
                        720_000L
                    )
                )
            }
    }
    private fun releaseWakeLock() {
        if (wakeLock?.isHeld == true) {
            try {
                wakeLock?.release()
            } catch (_: Exception) {
            }
        }
        wakeLock = null
    }
    private fun enterForegroundImmediately() {
        val notification =
            notificationBuilder()
                .setContentTitle("MARANATHA")
                .setContentText(
                    "PrÃ©dication programmÃ©e"
                )
                .build()
        startForegroundCompat(notification)
    }
    private fun updateNotification(
        alarm: SermonAlarm
    ) {
        val notification =
            notificationBuilder()
                .setContentTitle(
                    "MARANATHA â€” prÃ©dication programmÃ©e"
                )
                .setContentText(alarm.title)
                .build()
        val manager =
            getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager
        manager.notify(
            NOTIFICATION_ID,
            notification
        )
    }
    private fun notificationBuilder():
        Notification.Builder {
        val intent =
            Intent(
                this,
                MainActivity::class.java
            ).apply {
                flags =
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
        val openIntent =
            PendingIntent.getActivity(
                this,
                NOTIFICATION_ID,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )
        val builder =
            if (
                Build.VERSION.SDK_INT >=
                Build.VERSION_CODES.O
            ) {
                Notification.Builder(
                    this,
                    CHANNEL_ID
                )
            } else {
                Notification.Builder(this)
            }
        return builder
            .setSmallIcon(
                R.drawable.ic_notification
            )
            .setContentIntent(openIntent)
            .setCategory(
                NotificationCompat.CATEGORY_SERVICE
            )
            .setOngoing(true)
            .setOnlyAlertOnce(true)
    }
    private fun startForegroundCompat(
        notification: Notification
    ) {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.Q
        ) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                2
            )
        } else {
            startForeground(
                NOTIFICATION_ID,
                notification
            )
        }
    }
    private fun stopForegroundCompat() {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.N
        ) {
            stopForeground(
                STOP_FOREGROUND_REMOVE
            )
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
    }
    private fun createNotificationChannel() {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.O
        ) {
            return
        }
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "PrÃ©dication programmÃ©e",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description =
                    "Maintient la programmation Maranatha active"
                setSound(null, null)
                enableVibration(false)
            }
        val manager =
            getSystemService(
                Context.NOTIFICATION_SERVICE
            ) as NotificationManager
        manager.createNotificationChannel(
            channel
        )
    }
    override fun onDestroy() {
        handler.removeCallbacks(
            triggerRunnable
        )
        releaseWakeLock()
        super.onDestroy()
    }
    override fun onBind(
        intent: Intent?
    ): IBinder? = null
}