package com.cemmmaranatha.maranatha

import android.content.Context
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

object MaranathaLiveStore {
    private const val PREFS = "maranatha_live"
    private const val ITEMS = "scheduled_items"
    private const val SNOOZES = "snoozed_items"
    private const val ACTIVE = "active_item"
    private const val ENABLED = "enabled"
    private const val SETUP_COMPLETED = "setup_completed"
    private const val DISMISSED_ID = "dismissed_live_id"

    fun deviceContext(context: Context): Context {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) {
            return context
        }

        if (context.isDeviceProtectedStorage) {
            return context
        }

        val protectedContext =
            context.createDeviceProtectedStorageContext()

        try {
            protectedContext.moveSharedPreferencesFrom(
                context,
                PREFS
            )
        } catch (_error: Exception) {
        }

        return protectedContext
    }

    private fun prefs(context: Context) =
        deviceContext(context)
            .getSharedPreferences(
                PREFS,
                Context.MODE_PRIVATE
            )

    fun enabled(context: Context): Boolean =
        prefs(context).getBoolean(ENABLED, true)

    fun setEnabled(
        context: Context,
        enabled: Boolean
    ) {
        prefs(context)
            .edit()
            .putBoolean(ENABLED, enabled)
            .apply()
    }

    fun setupCompleted(context: Context): Boolean =
        prefs(context)
            .getBoolean(SETUP_COMPLETED, false)

    fun setSetupCompleted(
        context: Context,
        value: Boolean
    ) {
        prefs(context)
            .edit()
            .putBoolean(SETUP_COMPLETED, value)
            .apply()
    }

    fun dismissed(
        context: Context,
        id: String
    ): Boolean {
        if (id.isBlank()) {
            return false
        }

        return prefs(context)
            .getString(DISMISSED_ID, "")
            .orEmpty() == id
    }

    fun setDismissed(
        context: Context,
        id: String
    ) {
        if (id.isBlank()) {
            return
        }

        prefs(context)
            .edit()
            .putString(DISMISSED_ID, id)
            .apply()
    }

    fun clearDismissed(
        context: Context,
        id: String? = null
    ) {
        val current =
            prefs(context)
                .getString(DISMISSED_ID, "")
                .orEmpty()

        if (id != null && id.isNotBlank() && current != id) {
            return
        }

        prefs(context)
            .edit()
            .remove(DISMISSED_ID)
            .apply()
    }

    fun save(
        context: Context,
        values: List<MaranathaLiveItem>
    ) {
        prefs(context)
            .edit()
            .putString(
                ITEMS,
                toArray(values).toString()
            )
            .apply()
    }

    fun read(context: Context): List<MaranathaLiveItem> =
        readArray(
            prefs(context)
                .getString(ITEMS, "[]")
                ?: "[]"
        )

    fun saveSnooze(
        context: Context,
        item: MaranathaLiveItem
    ) {
        val values =
            readSnoozes(context)
                .filterNot { it.id == item.id }
                .toMutableList()

        values.add(item)

        prefs(context)
            .edit()
            .putString(
                SNOOZES,
                toArray(values).toString()
            )
            .apply()
    }

    fun removeSnooze(
        context: Context,
        id: String
    ) {
        val values =
            readSnoozes(context)
                .filterNot { it.id == id }

        prefs(context)
            .edit()
            .putString(
                SNOOZES,
                toArray(values).toString()
            )
            .apply()
    }

    fun readSnoozes(
        context: Context
    ): List<MaranathaLiveItem> =
        readArray(
            prefs(context)
                .getString(SNOOZES, "[]")
                ?: "[]"
        )

    fun saveActive(
        context: Context,
        item: MaranathaLiveItem
    ) {
        prefs(context)
            .edit()
            .putString(
                ACTIVE,
                toJson(item).toString()
            )
            .apply()
    }

    fun readActive(
        context: Context
    ): MaranathaLiveItem? {
        val raw =
            prefs(context)
                .getString(ACTIVE, "")
                .orEmpty()

        if (raw.isBlank()) {
            return null
        }

        return try {
            fromJson(JSONObject(raw))
        } catch (_error: Exception) {
            null
        }
    }

    fun clearActive(context: Context) {
        prefs(context)
            .edit()
            .remove(ACTIVE)
            .apply()
    }

    private fun toArray(
        values: List<MaranathaLiveItem>
    ): JSONArray {
        val array = JSONArray()

        values.forEach {
            array.put(toJson(it))
        }

        return array
    }

    private fun toJson(
        item: MaranathaLiveItem
    ): JSONObject =
        JSONObject().apply {
            put("id", item.id)
            put("title", item.title)
            put("audioUrl", item.audioUrl)
            put(
                "triggerAtMillis",
                item.triggerAtMillis
            )
        }

    private fun fromJson(
        json: JSONObject
    ): MaranathaLiveItem? =
        MaranathaLiveItem.fromMap(
            mapOf(
                "id" to json.optString("id"),
                "title" to
                    json.optString("title"),
                "audioUrl" to
                    json.optString("audioUrl"),
                "triggerAtMillis" to
                    json.optLong(
                        "triggerAtMillis"
                    )
            )
        )

    private fun readArray(
        raw: String
    ): List<MaranathaLiveItem> {
        return try {
            val array = JSONArray(raw)

            buildList {
                for (i in 0 until array.length()) {
                    val item =
                        fromJson(
                            array.getJSONObject(i)
                        )

                    if (item != null) {
                        add(item)
                    }
                }
            }
        } catch (_error: Exception) {
            emptyList()
        }
    }
}
