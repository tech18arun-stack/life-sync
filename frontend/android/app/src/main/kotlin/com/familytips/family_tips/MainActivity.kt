package com.familytips.family_tips

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "deep_links"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        MethodChannel(binaryMessenger, CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialLink" -> {
                        val initialLink = intent?.data?.toString()
                        result.success(initialLink)
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Handle the intent when the app is already running
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        val data: Uri? = intent?.data
        if (data != null) {
            val binaryMessenger = flutterEngine?.dartExecutor?.binaryMessenger
            if (binaryMessenger != null) {
                val methodChannel = MethodChannel(binaryMessenger, CHANNEL)
                methodChannel.invokeMethod("onDeepLink", data.toString())
            }
        }
    }
}
