package com.cemmmaranatha.maranatha

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MaranathaLiveBridge.register(this, flutterEngine)
        MaranathaLiveBridge.handleIntent(intent)
        MaranathaFirebaseRegistrar.registerCurrentToken(this)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        MaranathaLiveBridge.handleIntent(intent)
        MaranathaFirebaseRegistrar.registerCurrentToken(this)
    }
}
