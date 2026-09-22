package com.cemmmaranatha.maranatha

data class MaranathaLiveItem(
    val id: String,
    val title: String,
    val audioUrl: String,
    val triggerAtMillis: Long
) {
    companion object {
        fun fromMap(value: Map<*, *>): MaranathaLiveItem? {
            val id =
                (value["id"] ?: value["_id"])
                    ?.toString()
                    ?.trim()
                    .orEmpty()

            val title =
                (value["title"] ?: value["titre"])
                    ?.toString()
                    ?.trim()
                    .orEmpty()

            val audioUrl =
                value["audioUrl"]
                    ?.toString()
                    ?.trim()
                    .orEmpty()

            val raw = value["triggerAtMillis"]

            val trigger =
                when (raw) {
                    is Number -> raw.toLong()
                    else ->
                        raw
                            ?.toString()
                            ?.toLongOrNull()
                            ?: System.currentTimeMillis()
                }

            if (id.isBlank() || audioUrl.isBlank()) {
                return null
            }

            return MaranathaLiveItem(
                id = id,
                title = title.ifBlank { "Direct MARANATHA" },
                audioUrl = audioUrl,
                triggerAtMillis = trigger
            )
        }
    }
}
