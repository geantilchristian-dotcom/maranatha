package com.cemmmaranatha.maranatha
import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
class MaranathaAlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOnLockScreen()
        val directTitle =
            intent.getStringExtra("title")
                ?.trim()
                .orEmpty()
                .ifBlank {
                    "Direct MARANATHA"
                }
        val root =
            LinearLayout(this).apply {
                orientation =
                    LinearLayout.VERTICAL
                gravity = Gravity.CENTER
                setPadding(
                    dp(28),
                    dp(40),
                    dp(28),
                    dp(40)
                )
                setBackgroundColor(
                    Color.rgb(
                        10,
                        22,
                        45
                    )
                )
            }
        val appName =
            TextView(this).apply {
                text = "MARANATHA"
                textSize = 26f
                setTextColor(Color.WHITE)
                setTypeface(
                    typeface,
                    Typeface.BOLD
                )
                gravity = Gravity.CENTER
            }
        val subtitle =
            TextView(this).apply {
                text =
                    "PRÉDICATION EN COURS"
                textSize = 13f
                setTextColor(
                    Color.rgb(
                        190,
                        205,
                        230
                    )
                )
                gravity = Gravity.CENTER
                setPadding(
                    0,
                    dp(12),
                    0,
                    dp(10)
                )
            }
        val title =
            TextView(this).apply {
                text = directTitle
                textSize = 21f
                setTextColor(Color.WHITE)
                gravity = Gravity.CENTER
                setTypeface(
                    typeface,
                    Typeface.BOLD
                )
                setPadding(
                    dp(8),
                    dp(12),
                    dp(8),
                    dp(40)
                )
            }
        val snooze =
            Button(this).apply {
                text =
                    "RAPPELER DANS 10 MIN"
                textSize = 16f
                isAllCaps = false
                setOnClickListener {
                    sendAction(
                        MaranathaLiveAudioService
                            .ACTION_SNOOZE
                    )
                    finishAndRemoveTask()
                }
            }
        val stop =
            Button(this).apply {
                text = "ARRÊTER"
                textSize = 16f
                isAllCaps = false
                setOnClickListener {
                    sendAction(
                        MaranathaLiveAudioService
                            .ACTION_STOP
                    )
                    finishAndRemoveTask()
                }
            }
        root.addView(
            appName,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )
        root.addView(
            subtitle,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )
        root.addView(
            title,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
        )
        root.addView(
            snooze,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(58)
            ).apply {
                bottomMargin = dp(16)
            }
        )
        root.addView(
            stop,
            LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dp(58)
            )
        )
        setContentView(root)
    }
    private fun showOnLockScreen() {
        if (
            Build.VERSION.SDK_INT >=
            Build.VERSION_CODES.O_MR1
        ) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams
                    .FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams
                        .FLAG_TURN_SCREEN_ON
            )
        }
        window.addFlags(
            WindowManager.LayoutParams
                .FLAG_KEEP_SCREEN_ON
        )
    }
    private fun sendAction(
        actionName: String
    ) {
        val service =
            Intent(
                this,
                MaranathaLiveAudioService::class.java
            ).apply {
                action = actionName
            }
        startService(service)
    }
    private fun dp(value: Int): Int {
        return (
            value *
                resources.displayMetrics.density
            ).toInt()
    }
}