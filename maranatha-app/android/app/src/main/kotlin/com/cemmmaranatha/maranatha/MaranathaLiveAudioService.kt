package com.cemmmaranatha.maranatha

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.app.NotificationCompat

class MaranathaLiveAudioService :
    Service() {

    companion object {
        const val CHANNEL_ID =
            "maranatha_direct_audio_v2"

        const val NOTIFICATION_ID =
            7401

        const val ACTION_PLAY =
            "maranatha.direct.PLAY"

        const val ACTION_PAUSE =
            "maranatha.direct.PAUSE"

        const val ACTION_RESUME =
            "maranatha.direct.RESUME"

        const val ACTION_STOP =
            "maranatha.direct.STOP"

        const val ACTION_SNOOZE =
            "maranatha.direct.SNOOZE"

        const val EXTRA_ID = "id"
        const val EXTRA_TITLE = "title"
        const val EXTRA_URL = "url"

        const val EXTRA_ORIGINAL_URL =
            "originalUrl"

        const val OPEN_DIRECT =
            "maranatha_open_direct"

        const val OPEN_DIRECT_ID =
            "maranatha_direct_id"
    }

    private var player:
        MediaPlayer? = null

    private var wakeLock:
        PowerManager.WakeLock? = null

    private lateinit var audioManager:
        AudioManager

    private var currentId = ""

    private var currentTitle =
        "Direct MARANATHA"

    private var currentSource = ""

    private var currentOriginalUrl = ""

    private var paused = false

    override fun onCreate() {
        super.onCreate()

        audioManager =
            getSystemService(
                Context.AUDIO_SERVICE
            ) as AudioManager

        createChannel()
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        if (intent == null) {
            restoreActive()
            return START_STICKY
        }

        when (intent.action) {
            ACTION_STOP -> {
                stopEverything(
                    markDismissed = true
                )

                return START_NOT_STICKY
            }

            ACTION_SNOOZE -> {
                snoozeCurrent()
                return START_NOT_STICKY
            }

            ACTION_PAUSE -> {
                pause()
                return START_STICKY
            }

            ACTION_RESUME -> {
                resume()
                return START_STICKY
            }

            ACTION_PLAY -> {
                val id =
                    intent
                        .getStringExtra(
                            EXTRA_ID
                        )
                        .orEmpty()

                val title =
                    intent
                        .getStringExtra(
                            EXTRA_TITLE
                        )
                        ?.trim()
                        .orEmpty()
                        .ifBlank {
                            "Direct MARANATHA"
                        }

                val source =
                    intent
                        .getStringExtra(
                            EXTRA_URL
                        )
                        ?.trim()
                        .orEmpty()

                val originalUrl =
                    intent
                        .getStringExtra(
                            EXTRA_ORIGINAL_URL
                        )
                        ?.trim()
                        .orEmpty()
                        .ifBlank {
                            source
                        }

                if (
                    id.isBlank() ||
                    source.isBlank()
                ) {
                    stopEverything(false)
                    return START_NOT_STICKY
                }

                if (
                    id == currentId &&
                    source == currentSource &&
                    player?.isPlaying == true
                ) {
                    updateNotification()
                    return START_STICKY
                }

                beginPlayback(
                    id = id,
                    title = title,
                    source = source,
                    originalUrl =
                        originalUrl
                )

                return START_STICKY
            }
        }

        return START_STICKY
    }

    private fun beginPlayback(
        id: String,
        title: String,
        source: String,
        originalUrl: String
    ) {
        releasePlayer()

        currentId = id
        currentTitle = title
        currentSource = source
        currentOriginalUrl =
            originalUrl
        paused = false

        val active =
            MaranathaLiveItem(
                id = currentId,
                title = currentTitle,
                audioUrl =
                    currentOriginalUrl,
                triggerAtMillis =
                    System.currentTimeMillis()
            )

        MaranathaLiveStore
            .saveActive(
                this,
                active
            )

        startForeground(
            NOTIFICATION_ID,
            notification(
                currentTitle,
                false
            )
        )

        requestFocus()
        acquireWakeLock()

        val media = MediaPlayer()
        player = media

        media.setAudioAttributes(
            AudioAttributes
                .Builder()
                .setUsage(
                    AudioAttributes
                        .USAGE_MEDIA
                )
                .setContentType(
                    AudioAttributes
                        .CONTENT_TYPE_SPEECH
                )
                .build()
        )

        media.setWakeMode(
            this,
            PowerManager
                .PARTIAL_WAKE_LOCK
        )

        media.setOnPreparedListener {
            it.start()
            updateNotification()
        }

        media.setOnCompletionListener {
            stopEverything(false)
        }

        media.setOnErrorListener {
                _player,
                _what,
                _extra ->
            stopEverything(false)
            true
        }

        try {
            media.setDataSource(source)
            media.prepareAsync()
        } catch (_error: Exception) {
            stopEverything(false)
        }
    }

    private fun restoreActive() {
        val item =
            MaranathaLiveStore
                .readActive(this)
                ?: return

        if (
            MaranathaLiveStore
                .dismissed(
                    this,
                    item.id
                )
        ) {
            MaranathaLiveStore
                .clearActive(this)
            return
        }

        val source =
            MaranathaLiveCache
                .resolveSource(
                    this,
                    item
                )

        beginPlayback(
            id = item.id,
            title = item.title,
            source = source,
            originalUrl =
                item.audioUrl
        )
    }

    private fun pause() {
        val current =
            player ?: return

        try {
            if (current.isPlaying) {
                current.pause()
                paused = true
                updateNotification()
            }
        } catch (_error: Exception) {
        }
    }

    private fun resume() {
        val current =
            player ?: return

        try {
            current.start()
            paused = false
            updateNotification()
        } catch (_error: Exception) {
        }
    }

    private fun snoozeCurrent() {
        if (
            currentId.isBlank() ||
            currentOriginalUrl.isBlank()
        ) {
            stopEverything(false)
            return
        }

        val item =
            MaranathaLiveItem(
                id = currentId,
                title = currentTitle,
                audioUrl =
                    currentOriginalUrl,
                triggerAtMillis =
                    System.currentTimeMillis()
            )

        MaranathaLiveScheduler
            .snooze(
                this,
                item,
                10
            )

        stopEverything(false)
    }

    private fun stopEverything(
        markDismissed: Boolean
    ) {
        if (
            markDismissed &&
            currentId.isNotBlank()
        ) {
            MaranathaLiveStore
                .setDismissed(
                    this,
                    currentId
                )
        }

        MaranathaLiveStore
            .clearActive(this)

        releasePlayer()
        releaseWakeLock()
        abandonFocus()

        currentId = ""
        currentSource = ""
        currentOriginalUrl = ""
        paused = false

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

        stopSelf()
    }

    private fun releasePlayer() {
        try {
            player?.stop()
        } catch (_error: Exception) {
        }

        try {
            player?.release()
        } catch (_error: Exception) {
        }

        player = null
    }

    private fun requestFocus() {
        @Suppress("DEPRECATION")
        audioManager.requestAudioFocus(
            null,
            AudioManager.STREAM_MUSIC,
            AudioManager.AUDIOFOCUS_GAIN
        )
    }

    private fun abandonFocus() {
        @Suppress("DEPRECATION")
        audioManager.abandonAudioFocus(
            null
        )
    }

    private fun acquireWakeLock() {
        if (
            wakeLock?.isHeld == true
        ) {
            return
        }

        val power =
            getSystemService(
                Context.POWER_SERVICE
            ) as PowerManager

        wakeLock =
            power.newWakeLock(
                PowerManager
                    .PARTIAL_WAKE_LOCK,
                "$packageName:maranathaDirect"
            ).apply {
                setReferenceCounted(false)

                acquire(
                    4 * 60 * 60 * 1000L
                )
            }
    }

    private fun releaseWakeLock() {
        try {
            if (
                wakeLock?.isHeld == true
            ) {
                wakeLock?.release()
            }
        } catch (_error: Exception) {
        }

        wakeLock = null
    }

    private fun updateNotification() {
        getSystemService(
            NotificationManager::class.java
        )?.notify(
            NOTIFICATION_ID,
            notification(
                currentTitle,
                paused
            )
        )
    }

    private fun notification(
        title: String,
        paused: Boolean
    ): Notification {
        val openApp =
            PendingIntent.getActivity(
                this,
                100,
                Intent(
                    this,
                    MainActivity::class.java
                ).apply {
                    flags =
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP

                    putExtra(
                        OPEN_DIRECT,
                        true
                    )

                    putExtra(
                        OPEN_DIRECT_ID,
                        currentId
                    )
                },
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        val alarmScreen =
            PendingIntent.getActivity(
                this,
                104,
                Intent(
                    this,
                    MaranathaAlarmActivity::class.java
                ).apply {
                    flags =
                        Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                    putExtra(
                        "title",
                        currentTitle
                    )
                },
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        val toggleAction =
            if (paused) {
                ACTION_RESUME
            } else {
                ACTION_PAUSE
            }

        val toggleIntent =
            PendingIntent.getService(
                this,
                101,
                Intent(
                    this,
                    MaranathaLiveAudioService::class.java
                ).apply {
                    action = toggleAction
                },
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        val snoozeIntent =
            PendingIntent.getService(
                this,
                102,
                Intent(
                    this,
                    MaranathaLiveAudioService::class.java
                ).apply {
                    action = ACTION_SNOOZE
                },
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        val stopIntent =
            PendingIntent.getService(
                this,
                103,
                Intent(
                    this,
                    MaranathaLiveAudioService::class.java
                ).apply {
                    action = ACTION_STOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or
                    PendingIntent.FLAG_IMMUTABLE
            )

        return NotificationCompat
            .Builder(
                this,
                CHANNEL_ID
            )
            .setSmallIcon(
                android.R.drawable
                    .ic_media_play
            )
            .setContentTitle(title)
            .setContentText(
                "Direct CEMM MARANATHA"
            )
            .setContentIntent(openApp)
            .setFullScreenIntent(alarmScreen, true)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setVisibility(
                NotificationCompat
                    .VISIBILITY_PUBLIC
            )
            .setCategory(
                NotificationCompat
                    .CATEGORY_ALARM
            )
            .setPriority(
                NotificationCompat
                    .PRIORITY_HIGH
            )
            .addAction(
                if (paused) {
                    android.R.drawable
                        .ic_media_play
                } else {
                    android.R.drawable
                        .ic_media_pause
                },
                if (paused) {
                    "Reprendre"
                } else {
                    "Pause"
                },
                toggleIntent
            )
            .addAction(
                android.R.drawable
                    .ic_lock_idle_alarm,
                "Rappeler 10 min",
                snoozeIntent
            )
            .addAction(
                android.R.drawable
                    .ic_menu_close_clear_cancel,
                "Arreter",
                stopIntent
            )
            .build()
    }

    private fun createChannel() {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.O
        ) {
            return
        }

        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "Direct MARANATHA",
                NotificationManager
                    .IMPORTANCE_HIGH
            ).apply {
                description =
                    "Lecture et rappel des directs MARANATHA"

                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility =
                    Notification
                        .VISIBILITY_PUBLIC
            }

        getSystemService(
            NotificationManager::class.java
        )?.createNotificationChannel(
            channel
        )
    }

    override fun onDestroy() {
        releasePlayer()
        releaseWakeLock()
        abandonFocus()
        super.onDestroy()
    }

    override fun onBind(
        intent: Intent?
    ): IBinder? = null
}
