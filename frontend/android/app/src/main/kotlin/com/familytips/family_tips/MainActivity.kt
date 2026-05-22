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
    private val OAUTH_TAG = "OAUTH"

    private var savedBundle: Bundle? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        savedBundle = savedInstanceState
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // 🔥 Deep Link Channel (OAuth)
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInitialLink" -> {
                    val initialLink = intent?.data?.toString()
                    result.success(initialLink)
                }
                else -> result.notImplemented()
            }
        }

        // 🔥 Start.io Ads Channel
        MethodChannel(messenger, STARTIO_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {

                "initStartio" -> {
                    val appId = call.argument<String>("appId")
                    val testMode = call.argument<Boolean>("testMode") ?: false

                    if (appId != null) {
                        try {
                            Log.d(TAG, "Initializing Start.io: $appId")
                            StartAppSDK.init(this, appId, false)

                            if (testMode) {
                                StartAppSDK.setTestAdsEnabled(true)
                            }

                            StartAppSDK.setUserConsent(this, "pas", System.currentTimeMillis(), true)
                            result.success(true)

                        } catch (e: Exception) {
                            Log.e(TAG, "Init error: ${e.message}")
                            result.error("INIT_ERROR", e.message, null)
                        }
                    } else {
                        result.error("INIT_ERROR", "App ID is null", null)
                    }
                }

                "showInterstitial" -> {
                    try {
                        val ad = StartAppAd(this)

                        ad.loadAd(StartAppAd.AdMode.AUTOMATIC,
                            object : com.startapp.sdk.adsbase.adlisteners.AdEventListener {

                                override fun onReceiveAd(adObj: com.startapp.sdk.adsbase.Ad) {
                                    ad.showAd()
                                    result.success(true)
                                }

                                override fun onFailedToReceiveAd(adObj: com.startapp.sdk.adsbase.Ad?) {
                                    result.error("AD_LOAD_FAILED", "Failed", null)
                                }
                            })
                    } catch (e: Exception) {
                        result.error("AD_ERROR", e.message, null)
                    }
                }

                "showVideoInterstitial" -> {
                    try {
                        val ad = StartAppAd(this)

                        ad.loadAd(StartAppAd.AdMode.VIDEO,
                            object : com.startapp.sdk.adsbase.adlisteners.AdEventListener {

                                override fun onReceiveAd(adObj: com.startapp.sdk.adsbase.Ad) {
                                    ad.showAd()
                                    result.success(true)
                                }

                                override fun onFailedToReceiveAd(adObj: com.startapp.sdk.adsbase.Ad?) {
                                    result.error("AD_LOAD_FAILED", "Failed", null)
                                }
                            })
                    } catch (e: Exception) {
                        result.error("AD_ERROR", e.message, null)
                    }
                }

                "showSplash" -> {
                    try {
                        val config = SplashConfig()
                            .setTheme(SplashConfig.Theme.BLAZE)
                            .setAppName("LifeSync")
                            .setOrientation(SplashConfig.Orientation.PORTRAIT)

                        StartAppAd.showSplash(this, savedBundle, config)
                        result.success(true)

                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "showRewarded" -> {
                    try {
                        val ad = StartAppAd(this)

                        ad.setVideoListener {
                            Log.d(TAG, "Rewarded finished")
                            result.success(true)
                        }

                        ad.loadAd(StartAppAd.AdMode.REWARDED_VIDEO,
                            object : com.startapp.sdk.adsbase.adlisteners.AdEventListener {

                                override fun onReceiveAd(adObj: com.startapp.sdk.adsbase.Ad) {
                                    val shown = ad.showAd()
                                    if (!shown) result.success(false)
                                }

                                override fun onFailedToReceiveAd(adObj: com.startapp.sdk.adsbase.Ad?) {
                                    result.success(false)
                                }
                            })
                    } catch (e: Exception) {
                        result.error("AD_ERROR", e.message, null)
                    }
                }

                "showReturnAd" -> {
                    try {
                        StartAppAd.enableAutoInterstitial()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("AD_ERROR", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        // 🔥 Register Ad Views
        flutterEngine.platformViewsController.registry.registerViewFactory(
            "startio_banner", StartioBannerFactory()
        )

        flutterEngine.platformViewsController.registry.registerViewFactory(
            "startio_mrec", StartioMrecFactory()
        )

        // 🔥 Handle initial OAuth intent
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        this.intent = intent
        handleIntent(intent)
    }

    // 🔥 OAUTH HANDLER (MOST IMPORTANT)
    private fun handleIntent(intent: Intent?) {
        val data: Uri? = intent?.data

        if (data != null) {
            Log.d(OAUTH_TAG, "Deep link received: $data")

            if (data.toString().startsWith("appwrite-callback-69e45bf20039aebb88ac://")) {

                val messenger = flutterEngine?.dartExecutor?.binaryMessenger

                if (messenger != null) {
                    MethodChannel(messenger, CHANNEL)
                        .invokeMethod("onDeepLink", data.toString())
                }
            }
        }
    }

    // 🔥 Banner View
    inner class StartioBannerFactory :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {

        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            return object : PlatformView {
                private val banner = Banner(context)

                override fun getView(): View = banner
                override fun dispose() {}
            }
        }
    }

    // 🔥 MREC View
    inner class StartioMrecFactory :
        PlatformViewFactory(StandardMessageCodec.INSTANCE) {

        override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
            return object : PlatformView {
                private val mrec = Mrec(context)

                override fun getView(): View = mrec
                override fun dispose() {}
            }
        }
    }
}