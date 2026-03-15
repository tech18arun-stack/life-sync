package com.familytips.family_tips

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import com.startapp.sdk.adsbase.StartAppSDK
import com.startapp.sdk.adsbase.StartAppAd
import com.startapp.sdk.ads.splash.SplashConfig
import com.startapp.sdk.ads.banner.Banner
import com.startapp.sdk.ads.banner.Mrec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.common.StandardMessageCodec
import android.content.Context
import android.view.View

class MainActivity : FlutterFragmentActivity() {

    private val CHANNEL = "deep_links"
    private val STARTIO_CHANNEL = "startio_ads"
    private val TAG = "StartApp"
    private var savedBundle: Bundle? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        savedBundle = savedInstanceState

        // Start.io SDK will be initialized via MethodChannel from Flutter later

    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val binaryMessenger = flutterEngine.dartExecutor.binaryMessenger

        // Deep Link Channel
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

        // Start.io Ads Channel
        MethodChannel(binaryMessenger, STARTIO_CHANNEL).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "initStartio" -> {
                        val appId = call.argument<String>("appId")
                        if (appId != null) {
                            Log.d(TAG, "Initialize Start.io SDK requested with App ID: $appId")
                            try {
                                StartAppSDK.init(this@MainActivity, appId, false)
                                StartAppSDK.setUserConsent(this@MainActivity, "pas", System.currentTimeMillis(), true)
                                result.success(true)
                            } catch (e: Exception) {
                                Log.e(TAG, "Error initializing Start.io: ${e.message}")
                                result.error("INIT_ERROR", e.message, null)
                            }
                        } else {
                            result.error("INIT_ERROR", "App ID is null", null)
                        }
                    }
                    "showInterstitial" -> {
                        Log.d(TAG, "Interstitial ad requested")
                        try {
                            val startAppAd = StartAppAd(this@MainActivity)
                            startAppAd.loadAd(StartAppAd.AdMode.AUTOMATIC)
                            startAppAd.showAd()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error showing interstitial: ${e.message}")
                            result.error("AD_ERROR", e.message, null)
                        }
                    }
                    "showVideoInterstitial" -> {
                        Log.d(TAG, "Video Interstitial requested")
                        try {
                            val startAppAd = StartAppAd(this@MainActivity)
                            startAppAd.loadAd(StartAppAd.AdMode.VIDEO)
                            startAppAd.showAd()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error showing video interstitial: ${e.message}")
                            result.error("AD_ERROR", e.message, null)
                        }
                    }
                    "showSplash" -> {
                        Log.d(TAG, "Splash ad requested")
                        try {
                            // Using SplashConfig from com.startapp.sdk.ads.splash
                            val splashConfig = SplashConfig()
                                .setTheme(SplashConfig.Theme.BLAZE)
                                .setAppName("LifeSync")
                                .setOrientation(SplashConfig.Orientation.PORTRAIT)
                            
                            StartAppAd.showSplash(this@MainActivity, savedBundle, splashConfig)
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error showing splash: ${e.message}")
                            // Fallback to default splash if config fails
                            try {
                                StartAppAd.showSplash(this@MainActivity, savedBundle)
                                result.success(true)
                            } catch (e2: Exception) {
                                result.success(false)
                            }
                        }
                    }
                    "showRewarded" -> {
                        Log.d(TAG, "Rewarded video requested")
                        try {
                            val startAppAd = StartAppAd(this@MainActivity)
                            startAppAd.loadAd(StartAppAd.AdMode.REWARDED_VIDEO)
                            startAppAd.showAd()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error showing rewarded: ${e.message}")
                            result.error("AD_ERROR", e.message, null)
                        }
                    }
                    "showReturnAd" -> {
                        Log.d(TAG, "Return ad requested")
                        try {
                            StartAppAd.enableAutoInterstitial()
                            result.success(true)
                        } catch (e: Exception) {
                            Log.e(TAG, "Error showing return ad: ${e.message}")
                            result.error("AD_ERROR", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
        }

        // Register Banner and MREC Platform Views
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "startio_banner", StartioBannerFactory()
        )
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "startio_mrec", StartioMrecFactory()
        )

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

    // Banner View Platform Factory
    internal inner class StartioBannerFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            return StartioBannerView(context)
        }
    }

    // Banner View Platform Implementation
    internal inner class StartioBannerView(context: Context) : PlatformView {
        private val banner: Banner = Banner(context)

        override fun getView(): View {
            return banner
        }

        override fun dispose() {
            // Banner doesn't have a specific dispose in this version
        }
    }

    // MREC View Platform Factory
    internal inner class StartioMrecFactory : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            return StartioMrecView(context)
        }
    }

    // MREC View Platform Implementation
    internal inner class StartioMrecView(context: Context) : PlatformView {
        private val mrec: Mrec = Mrec(context)

        override fun getView(): View {
            return mrec
        }

        override fun dispose() {
        }
    }
}
