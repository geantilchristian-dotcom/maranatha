package com.maranatha.app

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "maranatha/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {

                    // ── Gestion batterie ───────────────────────────────────
                    "requestIgnoreBatteryOptimizations" -> {
                        try {
                            val pm = getSystemService(POWER_SERVICE) as PowerManager
                            if (!pm.isIgnoringBatteryOptimizations(packageName)) {
                                val intent = Intent(
                                    Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                                ).apply { data = Uri.parse("package:$packageName") }
                                startActivity(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    "isIgnoringBatteryOptimizations" -> {
                        val pm = getSystemService(POWER_SERVICE) as PowerManager
                        result.success(pm.isIgnoringBatteryOptimizations(packageName))
                    }

                    "ouvrirParametresBatterie" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS))
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    // ── Service audio arrière-plan ─────────────────────────
                    // Démarrer : appelé dès que l'audio commence dans la WebView
                    "startAudioService" -> {
                        try {
                            val titre = call.argument<String>("titre") ?: "Maranatha"
                            val intent = Intent(this, AudioForegroundService::class.java).apply {
                                action = AudioForegroundService.ACTION_START
                                putExtra(AudioForegroundService.EXTRA_TITRE, titre)
                            }
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(intent)
                            } else {
                                startService(intent)
                            }
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    // Pause : met à jour la notification sans stopper le service
                    "pauseAudioService" -> {
                        try {
                            val intent = Intent(this, AudioForegroundService::class.java).apply {
                                action = AudioForegroundService.ACTION_PAUSE
                            }
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    // Stop : ferme complètement le foreground service
                    "stopAudioService" -> {
                        try {
                            val intent = Intent(this, AudioForegroundService::class.java).apply {
                                action = AudioForegroundService.ACTION_STOP
                            }
                            startService(intent)
                            result.success(true)
                        } catch (e: Exception) { result.success(false) }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
