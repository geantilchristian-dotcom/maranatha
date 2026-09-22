package com.cemmmaranatha.maranatha

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object MaranathaLiveBridge {
    private const val CHANNEL =
        "maranatha/live_audio"

    private const val NOTIFICATION_REQUEST =
        9201

    private var channel:
        MethodChannel? = null

    private var pendingDirectId = ""

    fun register(
        activity: Activity,
        flutterEngine: FlutterEngine
    ) {
        val methodChannel =
            MethodChannel(
                flutterEngine
                    .dartExecutor
                    .binaryMessenger,
                CHANNEL
            )

        channel = methodChannel

        methodChannel
            .setMethodCallHandler {
                    call,
                    result ->
                when (call.method) {
                    "enable" -> {
                        MaranathaLiveStore
                            .setEnabled(
                                activity,
                                true
                            )

                        result.success(true)
                    }

                    "sync" -> {
                        val list =
                            call.arguments
                                as? List<*>
                                ?: emptyList<Any>()

                        result.success(
                            MaranathaLiveScheduler
                                .sync(
                                    activity,
                                    list
                                )
                        )
                    }

                    "start" -> {
                        val args =
                            call.arguments
                                as? Map<*, *>

                        val item =
                            args?.let {
                                MaranathaLiveItem
                                    .fromMap(
                                        mapOf(
                                            "id" to
                                                it["id"],
                                            "title" to
                                                it["title"],
                                            "audioUrl" to
                                                it["audioUrl"],
                                            "triggerAtMillis" to
                                                System
                                                    .currentTimeMillis()
                                        )
                                    )
                            }

                        if (item == null) {
                            result.error(
                                "INVALID",
                                "Direct invalide",
                                null
                            )
                        } else {
                            MaranathaLiveStore
                                .clearDismissed(
                                    activity,
                                    item.id
                                )

                            MaranathaLiveCache
                                .prefetchAsync(
                                    activity,
                                    listOf(item)
                                )

                            val source =
                                MaranathaLiveCache
                                    .resolveSource(
                                        activity,
                                        item
                                    )

                            val service =
                                Intent(
                                    activity,
                                    MaranathaLiveAudioService::class.java
                                ).apply {
                                    action =
                                        MaranathaLiveAudioService
                                            .ACTION_PLAY

                                    putExtra(
                                        MaranathaLiveAudioService
                                            .EXTRA_ID,
                                        item.id
                                    )

                                    putExtra(
                                        MaranathaLiveAudioService
                                            .EXTRA_TITLE,
                                        item.title
                                    )

                                    putExtra(
                                        MaranathaLiveAudioService
                                            .EXTRA_URL,
                                        source
                                    )

                                    putExtra(
                                        MaranathaLiveAudioService
                                            .EXTRA_ORIGINAL_URL,
                                        item.audioUrl
                                    )
                                }

                            ContextCompat
                                .startForegroundService(
                                    activity,
                                    service
                                )

                            result.success(true)
                        }
                    }

                    "pause" -> {
                        activity.startService(
                            Intent(
                                activity,
                                MaranathaLiveAudioService::class.java
                            ).apply {
                                action =
                                    MaranathaLiveAudioService.ACTION_PAUSE
                            }
                        )
                        result.success(true)
                    }
                    "resume" -> {
                        activity.startService(
                            Intent(
                                activity,
                                MaranathaLiveAudioService::class.java
                            ).apply {
                                action =
                                    MaranathaLiveAudioService.ACTION_RESUME
                            }
                        )
                        result.success(true)
                    }
                    "volume" -> {
                        val args =
                            call.arguments as? Map<*, *>
                        val raw =
                            args?.get("value")
                        val value =
                            when (raw) {
                                is Number ->
                                    raw.toDouble()
                                else ->
                                    raw
                                        ?.toString()
                                        ?.toDoubleOrNull()
                                        ?: 1.0
                            }
                                .coerceIn(
                                    0.0,
                                    1.0
                                )
                        val audioManager =
                            activity.getSystemService(
                                android.content.Context.AUDIO_SERVICE
                            ) as android.media.AudioManager
                        val maximum =
                            audioManager.getStreamMaxVolume(
                                android.media.AudioManager.STREAM_MUSIC
                            )
                        val target =
                            (maximum * value)
                                .toInt()
                                .coerceIn(
                                    0,
                                    maximum
                                )
                        audioManager.setStreamVolume(
                            android.media.AudioManager.STREAM_MUSIC,
                            target,
                            0
                        )
                        result.success(true)
                    }                    "stop" -> {
                        activity.startService(
                            Intent(
                                activity,
                                MaranathaLiveAudioService::class.java
                            ).apply {
                                action =
                                    MaranathaLiveAudioService
                                        .ACTION_STOP
                            }
                        )

                        result.success(true)
                    }

                    "requestNotificationPermission" -> {
                        requestNotifications(
                            activity
                        )

                        result.success(true)
                    }

                    "requestExactAlarm" -> {
                        requestExactAlarm(
                            activity
                        )

                        result.success(true)
                    }

                    "requestBattery" -> {
                        requestBattery(
                            activity
                        )

                        result.success(true)
                    }

                    "permissions" -> {
                        result.success(
                            permissionMap(
                                activity
                            )
                        )
                    }

                    "setupStatus" -> {
                        val values =
                            permissionMap(
                                activity
                            ).toMutableMap()

                        values["completed"] =
                            MaranathaLiveStore
                                .setupCompleted(
                                    activity
                                )

                        result.success(values)
                    }

                    "completeSetup" -> {
                        val values =
                            permissionMap(
                                activity
                            )

                        val complete =
                            values.values
                                .all { it }

                        if (complete) {
                            MaranathaLiveStore
                                .setSetupCompleted(
                                    activity,
                                    true
                                )
                        }

                        result.success(complete)
                    }

                    "consumePendingDirect" -> {
                        val value =
                            pendingDirectId

                        pendingDirectId = ""

                        result.success(value)
                    }

                    "isDismissed" -> {
                        val args =
                            call.arguments
                                as? Map<*, *>

                        val id =
                            args
                                ?.get("id")
                                ?.toString()
                                .orEmpty()

                        result.success(
                            MaranathaLiveStore
                                .dismissed(
                                    activity,
                                    id
                                )
                        )
                    }

                    else ->
                        result.notImplemented()
                }
            }
    }

    fun handleIntent(
        intent: Intent?
    ) {
        if (
            intent?.getBooleanExtra(
                MaranathaLiveAudioService
                    .OPEN_DIRECT,
                false
            ) != true
        ) {
            return
        }

        val id =
            intent.getStringExtra(
                MaranathaLiveAudioService
                    .OPEN_DIRECT_ID
            ).orEmpty()

        pendingDirectId = id

        channel?.invokeMethod(
            "openDirect",
            mapOf("id" to id)
        )
    }

    private fun permissionMap(
        activity: Activity
    ): Map<String, Boolean> {
        val notifications =
            Build.VERSION.SDK_INT < 33 ||
            ContextCompat
                .checkSelfPermission(
                    activity,
                    Manifest.permission
                        .POST_NOTIFICATIONS
                ) ==
            PackageManager
                .PERMISSION_GRANTED

        val exact =
            MaranathaLiveScheduler
                .canScheduleExact(
                    activity
                )

        val battery =
            if (
                Build.VERSION.SDK_INT <
                Build.VERSION_CODES.M
            ) {
                true
            } else {
                (
                    activity.getSystemService(
                        Activity.POWER_SERVICE
                    ) as PowerManager
                )
                    .isIgnoringBatteryOptimizations(
                        activity.packageName
                    )
            }

        return mapOf(
            "notifications" to
                notifications,
            "exactAlarm" to exact,
            "battery" to battery
        )
    }

    private fun requestNotifications(
        activity: Activity
    ) {
        if (
            Build.VERSION.SDK_INT >= 33 &&
            ContextCompat
                .checkSelfPermission(
                    activity,
                    Manifest.permission
                        .POST_NOTIFICATIONS
                ) !=
            PackageManager
                .PERMISSION_GRANTED
        ) {
            ActivityCompat
                .requestPermissions(
                    activity,
                    arrayOf(
                        Manifest.permission
                            .POST_NOTIFICATIONS
                    ),
                    NOTIFICATION_REQUEST
                )
        }
    }

    private fun requestExactAlarm(
        activity: Activity
    ) {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.S ||
            MaranathaLiveScheduler
                .canScheduleExact(
                    activity
                )
        ) {
            return
        }

        try {
            activity.startActivity(
                Intent(
                    Settings
                        .ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                ).apply {
                    data =
                        Uri.parse(
                            "package:${activity.packageName}"
                        )
                }
            )
        } catch (_error: Exception) {
        }
    }

    private fun requestBattery(
        activity: Activity
    ) {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.M
        ) {
            return
        }

        val power =
            activity.getSystemService(
                Activity.POWER_SERVICE
            ) as PowerManager

        if (
            power
                .isIgnoringBatteryOptimizations(
                    activity.packageName
                )
        ) {
            return
        }

        try {
            activity.startActivity(
                Intent(
                    Settings
                        .ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                ).apply {
                    data =
                        Uri.parse(
                            "package:${activity.packageName}"
                        )
                }
            )
        } catch (_error: Exception) {
        }
    }
}
