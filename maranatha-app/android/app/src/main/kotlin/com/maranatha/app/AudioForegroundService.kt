package com.maranatha.app

import android.app.*
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.ServiceCompat

/**
 * Foreground Service audio — maintient la lecture active quand :
 *   • l'écran est verrouillé
 *   • l'app est en arrière-plan
 *   • Android tente d'économiser la batterie
 *
 * Compatible API 21+ (Android 5.0+).
 * minSdk du projet = 21, donc on ne peut PAS utiliser
 * STOP_FOREGROUND_REMOVE (API 33) directement.
 */
class AudioForegroundService : Service() {

    companion object {
        const val CHANNEL_ID   = "maranatha_audio_bg"
        const val NOTIF_ID     = 2001
        const val ACTION_START = "com.maranatha.app.AUDIO_START"
        const val ACTION_PAUSE = "com.maranatha.app.AUDIO_PAUSE"
        const val ACTION_STOP  = "com.maranatha.app.AUDIO_STOP"
        const val EXTRA_TITRE  = "titre"
    }

    override fun onCreate() {
        super.onCreate()
        creerCanal()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val titre = intent?.getStringExtra(EXTRA_TITRE) ?: "Maranatha"
        return when (intent?.action) {
            ACTION_STOP -> {
                // Compatibilité API 21-32 et 33+
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                stopSelf()
                START_NOT_STICKY
            }
            else -> {
                startForeground(NOTIF_ID, construireNotification(titre))
                START_STICKY
            }
        }
    }

    private fun construireNotification(titre: String): Notification {
        val pi = PendingIntent.getActivity(
            this, 0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setContentTitle(titre)
            .setContentText("Communauté des Églises Missionnaires Maranatha")
            .setContentIntent(pi)
            .setOngoing(true)
            .setSilent(true)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .build()
    }

    private fun creerCanal() {
        val ch = NotificationChannel(
            CHANNEL_ID, "Lecture audio Maranatha",
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = "Maintient la lecture audio en arrière-plan"
            setSound(null, null)
            enableVibration(false)
        }
        getSystemService(NotificationManager::class.java)?.createNotificationChannel(ch)
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
