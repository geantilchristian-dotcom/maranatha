package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;
import io.flutter.embedding.engine.FlutterEngine;

/**
 * Fichier régénéré automatiquement par Flutter après `flutter pub get`.
 */
@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";

  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(
          new xyz.luan.audioplayers.AudioplayersPlugin());
    } catch (Exception error) {
      Log.e(TAG, "Erreur audioplayers", error);
    }

    try {
      flutterEngine.getPlugins().add(
          new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    } catch (Exception error) {
      Log.e(TAG, "Erreur shared_preferences", error);
    }

    try {
      flutterEngine.getPlugins().add(
          new io.flutter.plugins.webviewflutter.WebViewFlutterPlugin());
    } catch (Exception error) {
      Log.e(TAG, "Erreur webview_flutter", error);
    }
  }
}
