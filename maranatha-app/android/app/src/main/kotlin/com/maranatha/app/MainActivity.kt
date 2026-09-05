package com.maranatha.app
import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import com.google.firebase.messaging.FirebaseMessaging
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
    companion object {
        private const val CHANNEL = "maranatha/system"
        private const val NOTIFICATION_PERMISSION_REQUEST = 5102
    }
    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "syncSchedules" -> {
                    val values =
                        call.arguments as? List<*>
                            ?: emptyList<Any?>()
                    val alarms =
                        values.mapNotNull {
                            parseAlarmMap(it)
                        }
                    AlarmScheduler.syncServerAlarms(
                        this,
                        alarms
                    )
                    MaranathaKeeperService.sync(
                        this,
                        alarms
                    )
                    result.success(
                        mapOf(
                            "count" to alarms.size,
                            "exact" to
                                AlarmScheduler.canScheduleExact(this)
                        )
                    )
                }
                "setAlarmModeEnabled" -> {
                    val enabled =
                        call.argument<Boolean>(
                            "enabled"
                        ) ?: false
                    AlarmStore.setModeEnabled(
                        this,
                        enabled
                    )
                    if (enabled) {
                        AlarmScheduler.rescheduleAll(
                            this
                        )
                        MaranathaKeeperService.sync(
                            this,
                            AlarmStore.getAll(this)
                        )
                    } else {
                        AlarmScheduler.cancelAll(
                            this
                        )
                        stopService(
                            Intent(
                                this,
                                MaranathaKeeperService::class.java
                            )
                        )
                        stopService(
                            Intent(
                                this,
                                MaranathaAlarmService::class.java
                            )
                        )
                    }
                    result.success(true)
                }
                "isAlarmModeEnabled" -> {
                    result.success(
                        AlarmStore.isModeEnabled(this)
                    )
                }
                "getAlarmPermissions" -> {
                    result.success(
                        getAlarmPermissions()
                    )
                }
                "requestNotificationPermission" -> {
                    if (
                        Build.VERSION.SDK_INT >= 33 &&
                        checkSelfPermission(
                            Manifest.permission.POST_NOTIFICATIONS
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        requestPermissions(
                            arrayOf(
                                Manifest.permission.POST_NOTIFICATIONS
                            ),
                            NOTIFICATION_PERMISSION_REQUEST
                        )
                    }
                    result.success(true)
                }
                "requestExactAlarmPermission" -> {
                    requestExactAlarmPermission()
                    result.success(true)
                }
                "requestFullScreenIntentPermission" -> {
                    requestFullScreenIntentPermission()
                    result.success(true)
                }
                "requestIgnoreBatteryOptimizations" -> {
                    result.success(
                        requestIgnoreBatteryOptimizations()
                    )
                }
                "isIgnoringBatteryOptimizations" -> {
                    val powerManager =
                        getSystemService(
                            POWER_SERVICE
                        ) as PowerManager
                    result.success(
                        powerManager
                            .isIgnoringBatteryOptimizations(
                                packageName
                            )
                    )
                }
                "scheduleTestAlarm" -> {
                    val seconds =
                        (
                            call.argument<Number>(
                                "seconds"
                            )?.toLong() ?: 60L
                        ).coerceIn(
                            10L,
                            600L
                        )
                    val audioUrl =
                        call.argument<String>(
                            "audioUrl"
                        )
                            ?.trim()
                            .orEmpty()
                    val title =
                        call.argument<String>(
                            "title"
                        )
                            ?.trim()
                            .orEmpty()
                    if (audioUrl.isBlank()) {
                        result.error(
                            "AUDIO_REQUIRED",
                            "Une URL audio est nÃ©cessaire pour le test",
                            null
                        )
                        return@setMethodCallHandler
                    }
                    val triggerAt =
                        System.currentTimeMillis() +
                            seconds * 1000L
                    val alarm =
                        SermonAlarm(
                            id =
                                "test:$triggerAt",
                            title =
                                title.ifBlank {
                                    "Test du rÃ©veil Maranatha"
                                },
                            audioUrl =
                                audioUrl,
                            triggerAtMillis =
                                triggerAt
                        )
                    val exact =
                        AlarmScheduler.schedule(
                            this,
                            alarm,
                            false
                        )
                    result.success(
                        mapOf(
                            "scheduled" to true,
                            "exact" to exact,
                            "triggerAtMillis" to triggerAt
                        )
                    )
                }
                "getFcmToken" -> {
                    FirebaseMessaging
                        .getInstance()
                        .token
                        .addOnCompleteListener { task ->
                            if (
                                task.isSuccessful
                            ) {
                                val token =
                                    task.result
                                        .orEmpty()
                                if (
                                    token.isNotBlank()
                                ) {
                                    AlarmStore.saveFcmToken(
                                        this,
                                        token
                                    )
                                }
                                result.success(
                                    token
                                )
                            } else {
                                result.success(
                                    AlarmStore.getFcmToken(
                                        this
                                    )
                                )
                            }
                        }
                }
                "startAudioService" -> {
                    try {
                        val titre =
                            call.argument<String>(
                                AudioForegroundService.EXTRA_TITRE
                            ) ?: "Maranatha"
                        val intent =
                            Intent(
                                this,
                                AudioForegroundService::class.java
                            ).apply {
                                action =
                                    AudioForegroundService.ACTION_START
                                putExtra(
                                    AudioForegroundService.EXTRA_TITRE,
                                    titre
                                )
                            }
                        if (
                            Build.VERSION.SDK_INT >=
                            Build.VERSION_CODES.O
                        ) {
                            startForegroundService(
                                intent
                            )
                        } else {
                            startService(
                                intent
                            )
                        }
                        result.success(true)
                    } catch (
                        _error: Exception
                    ) {
                        result.success(false)
                    }
                }
                "pauseAudioService" -> {
                    try {
                        val intent =
                            Intent(
                                this,
                                AudioForegroundService::class.java
                            ).apply {
                                action =
                                    AudioForegroundService.ACTION_PAUSE
                            }
                        startService(intent)
                        result.success(true)
                    } catch (
                        _error: Exception
                    ) {
                        result.success(false)
                    }
                }
                "stopAudioService" -> {
                    try {
                        val intent =
                            Intent(
                                this,
                                AudioForegroundService::class.java
                            ).apply {
                                action =
                                    AudioForegroundService.ACTION_STOP
                            }
                        startService(intent)
                        result.success(true)
                    } catch (
                        _error: Exception
                    ) {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    override fun onResume() {
        super.onResume()
        if (
            AlarmStore.isModeEnabled(this)
        ) {
            AlarmScheduler.rescheduleAll(
                this
            )
            MaranathaKeeperService.sync(
                this,
                AlarmStore.getAll(this)
            )
        }
    }
    private fun parseAlarmMap(
        value: Any?
    ): SermonAlarm? {
        val map =
            value as? Map<*, *>
                ?: return null
        val id =
            (
                map["id"]
                    ?: map["_id"]
            )
                ?.toString()
                ?.trim()
                .orEmpty()
        val title =
            (
                map["title"]
                    ?: map["titre"]
            )
                ?.toString()
                ?.trim()
                .orEmpty()
        val audioUrl =
            map["audioUrl"]
                ?.toString()
                ?.trim()
                .orEmpty()
        val triggerValue =
            map["triggerAtMillis"]
        val triggerAt =
            when (
                triggerValue
            ) {
                is Number ->
                    triggerValue.toLong()
                else ->
                    triggerValue
                        ?.toString()
                        ?.toLongOrNull()
                        ?: 0L
            }
        if (
            id.isBlank() ||
            audioUrl.isBlank() ||
            triggerAt <= 0L
        ) {
            return null
        }
        return SermonAlarm(
            id = id,
            title =
                title.ifBlank {
                    "PrÃ©dication Maranatha"
                },
            audioUrl = audioUrl,
            triggerAtMillis = triggerAt
        )
    }
    private fun getAlarmPermissions():
        Map<String, Boolean> {
        val notificationGranted =
            Build.VERSION.SDK_INT < 33 ||
                checkSelfPermission(
                    Manifest.permission.POST_NOTIFICATIONS
                ) ==
                PackageManager.PERMISSION_GRANTED
        val fullScreenGranted =
            if (
                Build.VERSION.SDK_INT >= 34
            ) {
                val manager =
                    getSystemService(
                        NotificationManager::class.java
                    )
                manager?.canUseFullScreenIntent() == true
            } else {
                true
            }
        val powerManager =
            getSystemService(
                POWER_SERVICE
            ) as PowerManager
        return mapOf(
            "notifications" to
                notificationGranted,
            "exactAlarms" to
                AlarmScheduler.canScheduleExact(
                    this
                ),
            "fullScreen" to
                fullScreenGranted,
            "battery" to
                powerManager
                    .isIgnoringBatteryOptimizations(
                        packageName
                    ),
            "modeEnabled" to
                AlarmStore.isModeEnabled(
                    this
                )
        )
    }
    private fun requestExactAlarmPermission() {
        if (
            Build.VERSION.SDK_INT <
            Build.VERSION_CODES.S
        ) {
            return
        }
        val alarmManager =
            getSystemService(
                AlarmManager::class.java
            )
        if (
            alarmManager
                ?.canScheduleExactAlarms()
                == true
        ) {
            return
        }
        try {
            startActivity(
                Intent(
                    Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM
                ).apply {
                    data =
                        Uri.parse(
                            "package:$packageName"
                        )
                }
            )
        } catch (
            _error: Exception
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                ).apply {
                    data =
                        Uri.parse(
                            "package:$packageName"
                        )
                }
            )
        }
    }
    private fun requestFullScreenIntentPermission() {
        if (
            Build.VERSION.SDK_INT < 34
        ) {
            return
        }
        val manager =
            getSystemService(
                NotificationManager::class.java
            )
        if (
            manager?.canUseFullScreenIntent() == true
        ) {
            return
        }
        try {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT
                ).apply {
                    data =
                        Uri.parse(
                            "package:$packageName"
                        )
                }
            )
        } catch (
            _error: Exception
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS
                ).apply {
                    data =
                        Uri.parse(
                            "package:$packageName"
                        )
                }
            )
        }
    }
    private fun requestIgnoreBatteryOptimizations():
        Boolean {
        return try {
            val powerManager =
                getSystemService(
                    POWER_SERVICE
                ) as PowerManager
            if (
                powerManager
                    .isIgnoringBatteryOptimizations(
                        packageName
                    )
            ) {
                true
            } else {
                startActivity(
                    Intent(
                        Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                    ).apply {
                        data =
                            Uri.parse(
                                "package:$packageName"
                            )
                    }
                )
                true
            }
        } catch (
            _error: Exception
        ) {
            try {
                startActivity(
                    Intent(
                        Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS
                    )
                )
                true
            } catch (
                _error2: Exception
            ) {
                false
            }
        }
    }
}
