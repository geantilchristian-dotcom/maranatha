package com.cemmmaranatha.maranatha

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class MaranathaLiveBootReceiver :
    BroadcastReceiver() {

    override fun onReceive(
        context: Context,
        intent: Intent
    ) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_LOCKED_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED -> {
                MaranathaLiveScheduler
                    .rescheduleAll(context)
            }
        }
    }
}
