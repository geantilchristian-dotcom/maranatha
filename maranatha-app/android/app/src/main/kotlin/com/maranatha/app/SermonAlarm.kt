package com.maranatha.app

data class SermonAlarm(
    val id: String,
    val title: String,
    val audioUrl: String,
    val triggerAtMillis: Long,
)
