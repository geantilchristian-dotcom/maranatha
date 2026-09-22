package com.cemmmaranatha.maranatha
import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import java.io.File
import java.security.MessageDigest
object MaranathaLiveCache {
    private const val DOWNLOAD_PREFS =
        "maranatha_download_manager"
    private const val DOWNLOAD_PREFIX =
        "download_"
    private fun hash(
        value: String
    ): String =
        MessageDigest
            .getInstance("SHA-256")
            .digest(
                value.toByteArray(
                    Charsets.UTF_8
                )
            )
            .joinToString("") {
                (it.toInt() and 0xFF)
                    .toString(16)
                    .padStart(2, '0')
            }
    private fun legacyDirectory(
        context: Context
    ): File {
        val root =
            MaranathaLiveStore
                .deviceContext(context)
                .filesDir
        return File(
            root,
            "direct_audio"
        ).apply {
            if (!exists()) {
                mkdirs()
            }
        }
    }
    private fun externalDirectory(
        context: Context
    ): File {
        val musicRoot =
            context.getExternalFilesDir(
                Environment.DIRECTORY_MUSIC
            )
                ?: context.filesDir
        return File(
            musicRoot,
            "maranatha_direct"
        ).apply {
            if (!exists()) {
                mkdirs()
            }
        }
    }
    private fun legacyFileFor(
        context: Context,
        id: String
    ): File =
        File(
            legacyDirectory(context),
            "${hash(id)}.audio"
        )
    private fun fileFor(
        context: Context,
        id: String
    ): File =
        File(
            externalDirectory(context),
            "${hash(id)}.audio"
        )
    fun resolveSource(
        context: Context,
        item: MaranathaLiveItem
    ): String {
        val downloaded =
            fileFor(
                context,
                item.id
            )
        if (
            downloaded.exists() &&
            downloaded.length() > 0L
        ) {
            return downloaded.absolutePath
        }
        // Compatibilite avec les anciens fichiers
        val legacy =
            legacyFileFor(
                context,
                item.id
            )
        if (
            legacy.exists() &&
            legacy.length() > 0L
        ) {
            return legacy.absolutePath
        }
        // Si le téléchargement n'est pas encore fini,
        // MediaPlayer pourra toujours utiliser Internet.
        return item.audioUrl
    }
    fun prefetchAsync(
        context: Context,
        items: List<MaranathaLiveItem>
    ) {
        val appContext =
            context.applicationContext
        items.forEach { item ->
            enqueue(
                appContext,
                item
            )
        }
        cleanup(
            appContext,
            items
        )
    }
    private fun enqueue(
        context: Context,
        item: MaranathaLiveItem
    ) {
        if (
            !item.audioUrl.startsWith("https://") &&
            !item.audioUrl.startsWith("http://")
        ) {
            return
        }
        val target =
            fileFor(
                context,
                item.id
            )
        if (
            target.exists() &&
            target.length() > 0L
        ) {
            return
        }
        val manager =
            context.getSystemService(
                Context.DOWNLOAD_SERVICE
            ) as? DownloadManager
                ?: return
        val prefs =
            context.getSharedPreferences(
                DOWNLOAD_PREFS,
                Context.MODE_PRIVATE
            )
        val key =
            DOWNLOAD_PREFIX +
                hash(item.id)
        val existingId =
            prefs.getLong(
                key,
                -1L
            )
        if (existingId != -1L) {
            try {
                manager
                    .query(
                        DownloadManager
                            .Query()
                            .setFilterById(
                                existingId
                            )
                    )
                    ?.use { cursor ->
                        if (cursor.moveToFirst()) {
                            val status =
                                cursor.getInt(
                                    cursor.getColumnIndexOrThrow(
                                        DownloadManager
                                            .COLUMN_STATUS
                                    )
                                )
                            when (status) {
                                DownloadManager
                                    .STATUS_PENDING,
                                DownloadManager
                                    .STATUS_RUNNING,
                                DownloadManager
                                    .STATUS_PAUSED -> {
                                    return
                                }
                                DownloadManager
                                    .STATUS_SUCCESSFUL -> {
                                    if (
                                        target.exists() &&
                                        target.length() > 0L
                                    ) {
                                        return
                                    }
                                }
                            }
                        }
                    }
            } catch (
                _error: Exception
            ) {
            }
            prefs
                .edit()
                .remove(key)
                .apply()
        }
        try {
            if (
                target.exists() &&
                target.length() == 0L
            ) {
                target.delete()
            }
            val relativePath =
                "maranatha_direct/" +
                    "${hash(item.id)}.audio"
            val request =
                DownloadManager
                    .Request(
                        Uri.parse(
                            item.audioUrl
                        )
                    )
                    .apply {
                        setTitle(
                            item.title.ifBlank {
                                "MARANATHA"
                            }
                        )
                        setDescription(
                            "Préchargement de la prédication"
                        )
                        setMimeType(
                            "audio/mpeg"
                        )
                        setAllowedOverMetered(
                            true
                        )
                        setAllowedOverRoaming(
                            true
                        )
                        setNotificationVisibility(
                            DownloadManager
                                .Request
                                .VISIBILITY_VISIBLE
                        )
                        setDestinationInExternalFilesDir(
                            context,
                            Environment.DIRECTORY_MUSIC,
                            relativePath
                        )
                    }
            val downloadId =
                manager.enqueue(
                    request
                )
            prefs
                .edit()
                .putLong(
                    key,
                    downloadId
                )
                .apply()
        } catch (
            _error: Exception
        ) {
        }
    }
    private fun cleanup(
        context: Context,
        scheduled: List<MaranathaLiveItem>
    ) {
        val allItems =
            buildList {
                addAll(
                    scheduled
                )
                addAll(
                    MaranathaLiveStore
                        .readSnoozes(context)
                )
                MaranathaLiveStore
                    .readActive(context)
                    ?.let {
                        add(it)
                    }
            }
                .distinctBy {
                    it.id
                }
        val keepNames =
            allItems
                .map {
                    "${hash(it.id)}.audio"
                }
                .toSet()
        // Nettoyer l'ancien système .part
        legacyDirectory(context)
            .listFiles()
            ?.forEach { file ->
                if (
                    file.name.endsWith(".part")
                ) {
                    try {
                        file.delete()
                    } catch (
                        _error: Exception
                    ) {
                    }
                    return@forEach
                }
                if (
                    file.isFile &&
                    file.name !in keepNames
                ) {
                    try {
                        file.delete()
                    } catch (
                        _error: Exception
                    ) {
                    }
                }
            }
        externalDirectory(context)
            .listFiles()
            ?.forEach { file ->
                if (
                    file.isFile &&
                    file.name !in keepNames
                ) {
                    try {
                        file.delete()
                    } catch (
                        _error: Exception
                    ) {
                    }
                }
            }
        val manager =
            context.getSystemService(
                Context.DOWNLOAD_SERVICE
            ) as? DownloadManager
        val prefs =
            context.getSharedPreferences(
                DOWNLOAD_PREFS,
                Context.MODE_PRIVATE
            )
        val keepKeys =
            allItems
                .map {
                    DOWNLOAD_PREFIX +
                        hash(it.id)
                }
                .toSet()
        val editor =
            prefs.edit()
        prefs
            .all
            .forEach { entry ->
                if (
                    entry.key.startsWith(
                        DOWNLOAD_PREFIX
                    ) &&
                    entry.key !in keepKeys
                ) {
                    val id =
                        entry.value as? Long
                    if (
                        id != null &&
                        manager != null
                    ) {
                        try {
                            manager.remove(id)
                        } catch (
                            _error: Exception
                        ) {
                        }
                    }
                    editor.remove(
                        entry.key
                    )
                }
            }
        editor.apply()
    }
}
