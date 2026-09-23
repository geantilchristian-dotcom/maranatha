package com.cemmmaranatha.maranatha

import android.content.Intent
import io.flutter.plugin.common.MethodChannel
import android.os.Environment
import android.net.Uri
import android.content.Context
import android.app.DownloadManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MaranathaLiveBridge.register(this, flutterEngine)
        MaranathaLiveBridge.handleIntent(intent)
        MaranathaFirebaseRegistrar.registerCurrentToken(this)

        // MARANATHA_DOWNLOAD_MANAGER_V1
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.cemmmaranatha.maranatha/downloads",
        ).setMethodCallHandler { call, result ->
            if (call.method != "downloadPdf") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            try {
                val url =
                    call.argument<String>("url")
                        ?.trim()
                        .orEmpty()

                val rawName =
                    call.argument<String>("fileName")
                        ?.trim()
                        .orEmpty()

                if (url.isBlank()) {
                    result.error(
                        "URL_MISSING",
                        "URL PDF absente",
                        null,
                    )
                    return@setMethodCallHandler
                }

                val safeName =
                    rawName
                        .ifBlank {
                            "Livre-MARANATHA.pdf"
                        }
                        .replace(
                            Regex("[\\/:*?\"<>|]"),
                            "_",
                        )

                val request =
                    DownloadManager.Request(
                        Uri.parse(url),
                    )
                        .setTitle(safeName)
                        .setDescription(
                            "TÃ©lÃ©chargement MARANATHA",
                        )
                        .setMimeType(
                            "application/pdf",
                        )
                        .setNotificationVisibility(
                            DownloadManager.Request
                                .VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
                        )
                        .setAllowedOverMetered(true)
                        .setAllowedOverRoaming(true)
                        .setDestinationInExternalPublicDir(
                            Environment.DIRECTORY_DOWNLOADS,
                            safeName,
                        )

                val manager =
                    getSystemService(
                        Context.DOWNLOAD_SERVICE,
                    ) as DownloadManager

                val id =
                    manager.enqueue(request)

                result.success(id)
            } catch (error: Exception) {
                result.error(
                    "DOWNLOAD_FAILED",
                    error.message,
                    null,
                )
            }
        }
        // MARANATHA_DOWNLOAD_MANAGER_V1_END
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MaranathaLiveBridge.handleIntent(intent)
        MaranathaFirebaseRegistrar.registerCurrentToken(this)
    }
}
