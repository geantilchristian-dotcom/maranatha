package com.maranatha.app

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import java.io.File

object AudioCache {
    private const val PREFS = "maranatha_audio_downloads"

    fun prepare(context: Context, alarm: SermonAlarm) {
        val directory = context.getExternalFilesDir(Environment.DIRECTORY_MUSIC) ?: return
        val file = File(directory, fileName(alarm.id))
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
            ?: return
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val previousId = preferences.getLong(alarm.id, -1L)

        if (
            file.exists() &&
            file.length() > 0L &&
            (previousId <= 0L || downloadStatus(manager, previousId) == DownloadManager.STATUS_SUCCESSFUL)
        ) {
            return
        }

        if (previousId > 0L) {
            when (downloadStatus(manager, previousId)) {
                DownloadManager.STATUS_PENDING,
                DownloadManager.STATUS_RUNNING,
                DownloadManager.STATUS_PAUSED -> return
                DownloadManager.STATUS_SUCCESSFUL -> {
                    if (file.exists() && file.length() > 0L) return
                }
            }
            manager.remove(previousId)
            preferences.edit().remove(alarm.id).apply()
        }

        if (file.exists()) {
            file.delete()
        }

        try {
            val request = DownloadManager.Request(Uri.parse(alarm.audioUrl)).apply {
                setTitle("Préparation du réveil Maranatha")
                setDescription(alarm.title)
                setMimeType("audio/mpeg")
                setAllowedOverMetered(true)
                setAllowedOverRoaming(false)
                setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
                setDestinationInExternalFilesDir(
                    context,
                    Environment.DIRECTORY_MUSIC,
                    fileName(alarm.id),
                )
            }
            val downloadId = manager.enqueue(request)
            preferences.edit().putLong(alarm.id, downloadId).apply()
        } catch (_error: Exception) {
            // La lecture en ligne reste disponible au moment du réveil.
        }
    }

    fun sourceFor(context: Context, alarm: SermonAlarm): String {
        val directory = context.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
        val file = directory?.let { File(it, fileName(alarm.id)) }
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val downloadId = preferences.getLong(alarm.id, -1L)

        val ready = file?.exists() == true &&
            file.length() > 0L &&
            (
                downloadId <= 0L ||
                    (manager != null && downloadStatus(manager, downloadId) == DownloadManager.STATUS_SUCCESSFUL)
                )

        return if (ready) file!!.absolutePath else alarm.audioUrl
    }

    fun remove(context: Context, id: String) {
        val manager = context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
        val preferences = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val downloadId = preferences.getLong(id, -1L)
        if (downloadId > 0L) {
            manager?.remove(downloadId)
        }
        preferences.edit().remove(id).apply()

        context.getExternalFilesDir(Environment.DIRECTORY_MUSIC)
            ?.let { File(it, fileName(id)) }
            ?.takeIf { it.exists() }
            ?.delete()
    }

    private fun downloadStatus(manager: DownloadManager, downloadId: Long): Int {
        val cursor = manager.query(
            DownloadManager.Query().setFilterById(downloadId),
        ) ?: return -1

        cursor.use {
            if (!it.moveToFirst()) return -1
            val statusIndex = it.getColumnIndex(DownloadManager.COLUMN_STATUS)
            if (statusIndex < 0) return -1
            return it.getInt(statusIndex)
        }
    }

    private fun fileName(id: String): String {
        val safe = id.replace(Regex("[^A-Za-z0-9_-]"), "_").take(80)
        return "maranatha_$safe.mp3"
    }
}
