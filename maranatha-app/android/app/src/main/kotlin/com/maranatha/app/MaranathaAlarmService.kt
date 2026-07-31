package com.maranatha.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Color
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log

class MaranathaAlarmService : Service() {
    companion object {
        const val CHANNEL_ID = "maranatha_reveil_spirituel"
        const val NOTIFICATION_ID = 5101
        const val ACTION_START = "com.maranatha.app.REVEIL_START"
        const val ACTION_STOP = "com.maranatha.app.REVEIL_STOP"
        const val ACTION_SNOOZE = "com.maranatha.app.REVEIL_SNOOZE"
        private const val TAG = "MaranathaAlarm"
    }

    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var currentAlarm: SermonAlarm? = null
    private var audioManager: AudioManager? = null
    private var currentSource: String = ""

    private val focusListener = AudioManager.OnAudioFocusChangeListener { change ->
        if (change == AudioManager.AUDIOFOCUS_LOSS) {
            stopAlarm()
        }
    }

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopAlarm()
                return START_NOT_STICKY
            }

            ACTION_START -> {
                val alarm = with(AlarmScheduler) { intent.readAlarm() }
                    ?: return START_NOT_STICKY
                startAlarm(alarm)
            }
        }

        return START_NOT_STICKY
    }

    private fun startAlarm(alarm: SermonAlarm) {
        if (!AlarmStore.isModeEnabled(this)) {
            stopSelf()
            return
        }

        if (
            currentAlarm?.id == alarm.id ||
            AlarmStore.wasStartedRecently(this, alarm.id, 20 * 60 * 1000L)
        ) {
            return
        }

        releasePlayer()
        currentAlarm = alarm
        acquireWakeLock()

        val notification = buildNotification(
            alarm,
            "La prédication commence automatiquement",
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }

        @Suppress("DEPRECATION")
        audioManager?.requestAudioFocus(
            focusListener,
            AudioManager.STREAM_ALARM,
            AudioManager.AUDIOFOCUS_GAIN_TRANSIENT,
        )

        val source = AudioCache.sourceFor(applicationContext, alarm)
        preparePlayer(alarm, source, allowRemoteFallback = source != alarm.audioUrl)
    }

    private fun preparePlayer(
        alarm: SermonAlarm,
        source: String,
        allowRemoteFallback: Boolean,
    ) {
        releasePlayer()
        currentSource = source

        try {
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SPEECH)
                        .build(),
                )
                setWakeMode(applicationContext, PowerManager.PARTIAL_WAKE_LOCK)
                setDataSource(source)

                setOnPreparedListener { player ->
                    AlarmStore.markStarted(applicationContext, alarm.id)
                    player.start()
                    updateNotification(alarm, "Prédication en cours")
                }

                setOnCompletionListener {
                    stopAlarm()
                }

                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "Lecture impossible what=$what extra=$extra source=$currentSource")

                    if (allowRemoteFallback && alarm.audioUrl.isNotBlank()) {
                        AudioCache.remove(applicationContext, alarm.id)
                        preparePlayer(
                            alarm,
                            alarm.audioUrl,
                            allowRemoteFallback = false,
                        )
                    } else {
                        updateNotification(
                            alarm,
                            "Impossible de charger l’audio. Vérifiez la connexion Internet.",
                        )
                    }
                    true
                }

                prepareAsync()
            }
        } catch (error: Exception) {
            Log.e(TAG, "Erreur de préparation audio", error)

            if (allowRemoteFallback && alarm.audioUrl.isNotBlank()) {
                AudioCache.remove(applicationContext, alarm.id)
                preparePlayer(
                    alarm,
                    alarm.audioUrl,
                    allowRemoteFallback = false,
                )
            } else {
                updateNotification(
                    alarm,
                    "Impossible de charger l’audio. Vérifiez la connexion Internet.",
                )
            }
        }
    }

    private fun buildNotification(alarm: SermonAlarm, text: String): Notification {
        val activityIntent = Intent(this, AlarmActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
            with(AlarmScheduler) { putAlarm(alarm) }
        }
        val activityPendingIntent = PendingIntent.getActivity(
            this,
            alarm.id.hashCode(),
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val stopPendingIntent = actionPendingIntent(alarm, ACTION_STOP, 1)
        val snoozePendingIntent = actionPendingIntent(alarm, ACTION_SNOOZE, 2)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(alarm.title)
            .setContentText(text)
            .setContentIntent(activityPendingIntent)
            .setFullScreenIntent(activityPendingIntent, true)
            .setCategory(Notification.CATEGORY_ALARM)
            .setPriority(Notification.PRIORITY_MAX)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setColor(Color.rgb(213, 174, 50))
            .addAction(
                Notification.Action.Builder(
                    R.drawable.ic_notification,
                    "Rappeler dans 5 min",
                    snoozePendingIntent,
                ).build(),
            )
            .addAction(
                Notification.Action.Builder(
                    R.drawable.ic_notification,
                    "Arrêter",
                    stopPendingIntent,
                ).build(),
            )
            .build()
    }

    private fun actionPendingIntent(
        alarm: SermonAlarm,
        action: String,
        suffix: Int,
    ): PendingIntent {
        val intent = Intent(this, AlarmActionReceiver::class.java).apply {
            this.action = action
            with(AlarmScheduler) { putAlarm(alarm) }
        }

        return PendingIntent.getBroadcast(
            this,
            alarm.id.hashCode() xor suffix,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun updateNotification(alarm: SermonAlarm, text: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
        manager?.notify(NOTIFICATION_ID, buildNotification(alarm, text))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            CHANNEL_ID,
            "Réveil spirituel Maranatha",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Démarre automatiquement les prédications programmées"
            lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            setSound(null, null)
            enableVibration(true)
            vibrationPattern = longArrayOf(0L, 500L, 200L, 500L)
        }

        (getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager)
            ?.createNotificationChannel(channel)
    }

    private fun acquireWakeLock() {
        if (wakeLock?.isHeld == true) return

        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "Maranatha:PredicationWakeLock",
        ).apply {
            setReferenceCounted(false)
            acquire(4 * 60 * 60 * 1000L)
        }
    }

    private fun releasePlayer() {
        val player = mediaPlayer
        mediaPlayer = null
        currentSource = ""

        if (player != null) {
            try {
                player.setOnPreparedListener(null)
                player.setOnCompletionListener(null)
                player.setOnErrorListener(null)
                player.stop()
            } catch (_error: Exception) {
                // Le lecteur n’était pas encore prêt.
            }

            try {
                player.reset()
            } catch (_error: Exception) {
                // Le lecteur était déjà libéré.
            }

            try {
                player.release()
            } catch (_error: Exception) {
                // Rien d’autre à faire pendant l’arrêt.
            }
        }
    }

    private fun stopAlarm() {
        val alarmToClean = currentAlarm
        releasePlayer()
        currentAlarm = null
        if (alarmToClean != null) {
            AudioCache.remove(this, alarmToClean.id)
        }

        @Suppress("DEPRECATION")
        audioManager?.abandonAudioFocus(focusListener)

        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        stopSelf()
    }

    override fun onDestroy() {
        val alarmToClean = currentAlarm
        releasePlayer()
        currentAlarm = null
        if (alarmToClean != null) {
            AudioCache.remove(this, alarmToClean.id)
        }

        @Suppress("DEPRECATION")
        audioManager?.abandonAudioFocus(focusListener)

        if (wakeLock?.isHeld == true) {
            wakeLock?.release()
        }
        wakeLock = null

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
