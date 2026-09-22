package com.cemmmaranatha.maranatha
import android.content.Context
import android.util.Log
import com.google.firebase.FirebaseApp
import com.google.firebase.messaging.FirebaseMessaging
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.UUID
object MaranathaFirebaseRegistrar {
    private const val TAG =
        "MARANATHA-FCM"
    private const val REGISTER_URL =
        "https://maranatha-1-k6ro.onrender.com/api/devices/register"
    private const val PREFS =
        "maranatha_firebase"
    private const val INSTALLATION_ID =
        "installation_id"
    fun registerCurrentToken(
        context: Context
    ) {
        Log.i(
            TAG,
            "Etape 1 : demande du token Firebase"
        )
        try {
            val apps =
                FirebaseApp.getApps(context)
            Log.i(
                TAG,
                "Etape 2 : Firebase initialise, apps=${apps.size}"
            )
            FirebaseMessaging
                .getInstance()
                .isAutoInitEnabled = true
        } catch (
            error: Exception
        ) {
            Log.e(
                TAG,
                "FirebaseApp non initialise",
                error
            )
            return
        }
        FirebaseMessaging
            .getInstance()
            .token
            .addOnCompleteListener { task ->
                if (!task.isSuccessful) {
                    Log.e(
                        TAG,
                        "Etape 3 ECHEC : impossible d'obtenir le token",
                        task.exception
                    )
                    return@addOnCompleteListener
                }
                val token =
                    task.result
                        ?.trim()
                        .orEmpty()
                if (token.isBlank()) {
                    Log.e(
                        TAG,
                        "Etape 3 ECHEC : token vide"
                    )
                    return@addOnCompleteListener
                }
                Log.i(
                    TAG,
                    "Etape 3 OK : token obtenu, longueur=${token.length}"
                )
                registerToken(
                    context,
                    token
                )
            }
    }
    fun registerToken(
        context: Context,
        token: String
    ) {
        if (token.isBlank()) {
            return
        }
        val appContext =
            context.applicationContext
        Log.i(
            TAG,
            "Etape 4 : enregistrement du telephone sur le serveur"
        )
        Thread {
            var connection:
                HttpURLConnection? =
                null
            try {
                val payload =
                    JSONObject().apply {
                        put(
                            "installationId",
                            installationId(
                                appContext
                            )
                        )
                        put(
                            "fcmToken",
                            token
                        )
                        put(
                            "platform",
                            "android"
                        )
                        put(
                            "appVersion",
                            appVersion(
                                appContext
                            )
                        )
                        put(
                            "modeMaranathaActif",
                            MaranathaLiveStore
                                .enabled(
                                    appContext
                                )
                        )
                    }
                connection =
                    URL(
                        REGISTER_URL
                    )
                        .openConnection()
                            as HttpURLConnection
                connection.apply {
                    requestMethod =
                        "POST"
                    connectTimeout =
                        30_000
                    readTimeout =
                        30_000
                    doOutput =
                        true
                    setRequestProperty(
                        "Content-Type",
                        "application/json; charset=UTF-8"
                    )
                    setRequestProperty(
                        "Accept",
                        "application/json"
                    )
                }
                connection
                    .outputStream
                    .use { output ->
                        output.write(
                            payload
                                .toString()
                                .toByteArray(
                                    Charsets.UTF_8
                                )
                        )
                    }
                val code =
                    connection
                        .responseCode
                Log.i(
                    TAG,
                    "Etape 5 : serveur HTTP $code"
                )
                val stream =
                    if (code in 200..299) {
                        connection.inputStream
                    } else {
                        connection.errorStream
                    }
                val response =
                    try {
                        stream
                            ?.bufferedReader()
                            ?.use {
                                it.readText()
                            }
                            .orEmpty()
                    } catch (
                        _error: Exception
                    ) {
                        ""
                    }
                if (response.isNotBlank()) {
                    Log.i(
                        TAG,
                        "Reponse serveur : ${response.take(500)}"
                    )
                }
            } catch (
                error: Exception
            ) {
                Log.e(
                    TAG,
                    "Etape 5 ECHEC : enregistrement serveur impossible",
                    error
                )
            } finally {
                connection
                    ?.disconnect()
            }
        }.apply {
            name =
                "maranatha-fcm-register"
            isDaemon =
                true
            start()
        }
    }
    private fun installationId(
        context: Context
    ): String {
        val prefs =
            context
                .getSharedPreferences(
                    PREFS,
                    Context.MODE_PRIVATE
                )
        val current =
            prefs
                .getString(
                    INSTALLATION_ID,
                    ""
                )
                .orEmpty()
        if (current.isNotBlank()) {
            return current
        }
        val created =
            UUID
                .randomUUID()
                .toString()
        prefs
            .edit()
            .putString(
                INSTALLATION_ID,
                created
            )
            .apply()
        return created
    }
    private fun appVersion(
        context: Context
    ): String {
        return try {
            val info =
                context
                    .packageManager
                    .getPackageInfo(
                        context.packageName,
                        0
                    )
            info.versionName
                ?: "1"
        } catch (
            _error: Exception
        ) {
            "1"
        }
    }
}
