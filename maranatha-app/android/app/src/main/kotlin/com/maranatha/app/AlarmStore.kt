package com.maranatha.app

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

object AlarmStore {
    private const val PREFS = "maranatha_alarm_store"
    private const val KEY_ALARMS = "alarms"
    private const val KEY_MODE_ENABLED = "mode_enabled"
    private const val KEY_FCM_TOKEN = "fcm_token"
    private const val KEY_LAST_STARTED_ID = "last_started_id"
    private const val KEY_LAST_STARTED_AT = "last_started_at"

    @Synchronized
    fun save(context: Context, alarm: SermonAlarm) {
        val alarms = getAll(context).associateBy { it.id }.toMutableMap()
        alarms[alarm.id] = alarm
        writeAll(context, alarms.values.sortedBy { it.triggerAtMillis })
    }

    @Synchronized
    fun remove(context: Context, id: String) {
        val alarms = getAll(context).filterNot { it.id == id }
        writeAll(context, alarms)
    }

    @Synchronized
    fun get(context: Context, id: String): SermonAlarm? {
        return getAll(context).firstOrNull { it.id == id }
    }

    @Synchronized
    fun getAll(context: Context): List<SermonAlarm> {
        val raw = preferences(context).getString(KEY_ALARMS, "[]") ?: "[]"

        return try {
            val array = JSONArray(raw)
            buildList {
                for (index in 0 until array.length()) {
                    val item = array.optJSONObject(index) ?: continue
                    val id = item.optString("id").trim()
                    val title = item.optString("title").trim()
                    val audioUrl = item.optString("audioUrl").trim()
                    val triggerAtMillis = item.optLong("triggerAtMillis", 0L)

                    if (id.isNotEmpty() && audioUrl.isNotEmpty() && triggerAtMillis > 0L) {
                        add(
                            SermonAlarm(
                                id = id,
                                title = title.ifEmpty { "Prédication Maranatha" },
                                audioUrl = audioUrl,
                                triggerAtMillis = triggerAtMillis,
                            ),
                        )
                    }
                }
            }
        } catch (_error: Exception) {
            emptyList()
        }
    }

    @Synchronized
    fun replaceServerAlarms(context: Context, alarms: List<SermonAlarm>) {
        val snoozes = getAll(context).filter { it.id.startsWith("snooze:") }
        writeAll(
            context,
            (alarms + snoozes)
                .distinctBy { it.id }
                .sortedBy { it.triggerAtMillis },
        )
    }

    fun isModeEnabled(context: Context): Boolean {
        return preferences(context).getBoolean(KEY_MODE_ENABLED, false)
    }

    fun setModeEnabled(context: Context, enabled: Boolean) {
        preferences(context).edit().putBoolean(KEY_MODE_ENABLED, enabled).apply()
    }

    fun saveFcmToken(context: Context, token: String) {
        preferences(context).edit().putString(KEY_FCM_TOKEN, token).apply()
    }

    fun getFcmToken(context: Context): String {
        return preferences(context).getString(KEY_FCM_TOKEN, "") ?: ""
    }

    fun markStarted(context: Context, id: String) {
        preferences(context)
            .edit()
            .putString(KEY_LAST_STARTED_ID, id)
            .putLong(KEY_LAST_STARTED_AT, System.currentTimeMillis())
            .apply()
    }

    fun wasStartedRecently(context: Context, id: String, windowMillis: Long): Boolean {
        val prefs = preferences(context)
        val lastId = prefs.getString(KEY_LAST_STARTED_ID, "")
        val lastAt = prefs.getLong(KEY_LAST_STARTED_AT, 0L)
        return lastId == id && System.currentTimeMillis() - lastAt in 0..windowMillis
    }

    private fun writeAll(context: Context, alarms: Collection<SermonAlarm>) {
        val array = JSONArray()

        alarms.forEach { alarm ->
            array.put(
                JSONObject()
                    .put("id", alarm.id)
                    .put("title", alarm.title)
                    .put("audioUrl", alarm.audioUrl)
                    .put("triggerAtMillis", alarm.triggerAtMillis),
            )
        }

        preferences(context).edit().putString(KEY_ALARMS, array.toString()).apply()
    }

    private fun preferences(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
}
