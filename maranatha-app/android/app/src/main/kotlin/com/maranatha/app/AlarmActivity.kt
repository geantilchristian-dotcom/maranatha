package com.maranatha.app

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.view.WindowManager
import android.widget.Button
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.Space
import android.widget.TextView

class AlarmActivity : Activity() {
    private var alarm: SermonAlarm? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }

        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_ALLOW_LOCK_WHILE_SCREEN_ON,
        )
        window.statusBarColor = Color.rgb(3, 18, 30)
        window.navigationBarColor = Color.rgb(3, 18, 30)

        alarm = with(AlarmScheduler) { intent.readAlarm() }
        setContentView(buildContent())
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        alarm = with(AlarmScheduler) { intent.readAlarm() }
        setContentView(buildContent())
    }

    private fun buildContent(): LinearLayout {
        val density = resources.displayMetrics.density
        fun dp(value: Int) = (value * density).toInt()

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            setPadding(dp(26), dp(48), dp(26), dp(32))
            background = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(
                    Color.rgb(8, 40, 59),
                    Color.rgb(3, 18, 30),
                    Color.BLACK,
                ),
            )
        }

        val logo = ImageView(this).apply {
            setImageResource(R.mipmap.ic_launcher)
            scaleType = ImageView.ScaleType.CENTER_CROP
            background = roundedBackground(Color.WHITE, 28f)
            clipToOutline = true
        }
        root.addView(
            logo,
            LinearLayout.LayoutParams(dp(82), dp(82)).apply {
                bottomMargin = dp(28)
            },
        )

        root.addView(
            TextView(this).apply {
                text = "RÉVEIL SPIRITUEL"
                setTextColor(Color.rgb(213, 174, 50))
                textSize = 14f
                letterSpacing = 0.12f
                gravity = Gravity.CENTER
                setTypeface(typeface, Typeface.BOLD)
            },
        )

        root.addView(
            TextView(this).apply {
                text = alarm?.title ?: "Prédication Maranatha"
                setTextColor(Color.WHITE)
                textSize = 29f
                gravity = Gravity.CENTER
                setLineSpacing(0f, 1.12f)
                setTypeface(typeface, Typeface.BOLD)
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(14)
            },
        )

        root.addView(
            TextView(this).apply {
                text = "La prédication a démarré automatiquement"
                setTextColor(Color.argb(190, 255, 255, 255))
                textSize = 15f
                gravity = Gravity.CENTER
            },
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT,
            ).apply {
                topMargin = dp(12)
            },
        )

        root.addView(
            Space(this),
            LinearLayout.LayoutParams(1, 0, 1f),
        )

        val snoozeButton = Button(this).apply {
            text = "Rappeler dans 5 minutes"
            isAllCaps = false
            textSize = 15f
            setTextColor(Color.rgb(3, 18, 30))
            setTypeface(typeface, Typeface.BOLD)
            background = roundedBackground(Color.rgb(213, 174, 50), 18f)
            setOnClickListener { snooze() }
        }
        root.addView(
            snoozeButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(58),
            ).apply {
                bottomMargin = dp(12)
            },
        )

        val stopButton = Button(this).apply {
            text = "Arrêter la prédication"
            isAllCaps = false
            textSize = 15f
            setTextColor(Color.WHITE)
            setTypeface(typeface, Typeface.BOLD)
            background = roundedBackground(Color.rgb(192, 0, 26), 18f)
            setOnClickListener { stop() }
        }
        root.addView(
            stopButton,
            LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(58),
            ),
        )

        return root
    }

    private fun roundedBackground(color: Int, radius: Float): GradientDrawable {
        return GradientDrawable().apply {
            setColor(color)
            cornerRadius = radius * resources.displayMetrics.density
        }
    }

    private fun stop() {
        AlarmLauncher.stop(this)
        finishAndRemoveTask()
    }

    private fun snooze() {
        val current = alarm
        if (current != null) {
            AlarmScheduler.scheduleSnooze(this, current)
        }
        AlarmLauncher.stop(this)
        finishAndRemoveTask()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        // Une alarme ne doit pas disparaître sans action explicite.
    }
}
