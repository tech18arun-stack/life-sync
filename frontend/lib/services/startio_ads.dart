import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import './ad_block_detector.dart';

/// Start.io (StartApp) Ads Service
///
/// Provides interstitial, splash, banner, and rewarded ad functionality.
///
/// Setup completed:
/// ✅ AndroidManifest.xml configured with App ID: 201957244
/// ✅ MainActivity.kt initialized SDK with all ad types
/// ✅ Platform channel created for Flutter ↔ Native communication
/// ✅ Debug logging enabled for all ad events
class StartIOAds {
  static const MethodChannel _channel = MethodChannel('startio_ads');
  static final AdBlockDetector _detector = AdBlockDetector();

  /// Gets the current ad-blocker status
  static bool get isAdBlockerActive => _detector.isAdBlockerActive;

  /// Initialize Start.io Ads dynamically
  static Future<void> initialize(String appId) async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Initializing with App ID: $appId...');
      }
      
      // Check for ad-blockers during initialization
      await _detector.checkAdBlocker();
      
      await _channel.invokeMethod('initStartio', {'appId': appId});
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Initialization failed: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Unexpected error during init: $e');
      }
    }
  }

  /// Show an interstitial ad
  ///
  /// Best used at natural break points:
  /// - After completing a task
  /// - After adding expense/income
  /// - Every 3rd screen navigation
  static Future<void> showInterstitial() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Requesting interstitial ad...');
      }
      await _channel.invokeMethod('showInterstitial');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Interstitial ad failed: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Unexpected error: $e');
      }
    }
  }

  /// Show a video interstitial ad
  static Future<void> showVideoInterstitial() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Requesting video interstitial...');
      }
      await _channel.invokeMethod('showVideoInterstitial');
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Video interstitial failed: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Unexpected error: $e');
      }
    }
  }

  /// Show a splash ad on app launch
  ///
  /// Call this early in your app lifecycle.
  /// Note: Only show once per session.
  static Future<void> showSplash() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Requesting splash ad...');
      }
      await _channel.invokeMethod('showSplash');
      if (kDebugMode) {
        print('✅ [Start.io] Splash ad displayed successfully');
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Splash ad failed: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Unexpected error: $e');
      }
    }
  }

  /// Show a rewarded video ad
  ///
  /// Use for premium features:
  /// - Unlock AI insights
  /// - Get extra budget tips
  /// - Unlock premium themes
  ///
  /// Returns true if ad was shown successfully.
  static Future<bool> showRewarded() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Requesting rewarded video...');
      }
      final bool? result = await _channel.invokeMethod('showRewarded');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Rewarded video failed: ${e.message}');
      }
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Unexpected error: $e');
      }
      return false;
    }
  }

  /// Enable Automatic Return Ads
  /// Shows an ad when the user returns to the app
  static Future<void> showReturnAd() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Enabling auto return ads...');
      }
      await _channel.invokeMethod('showReturnAd');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Return ad setup failed: $e');
      }
    }
  }
}

/// Start.io Banner Ad Widget
class StartioBanner extends StatelessWidget {
  const StartioBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return const SizedBox(
      height: 50,
      width: double.infinity,
      child: AndroidView(
        viewType: 'startio_banner',
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}

/// Start.io MREC Ad Widget
class StartioMrec extends StatelessWidget {
  const StartioMrec({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }
    return const SizedBox(
      height: 250,
      width: 300,
      child: AndroidView(
        viewType: 'startio_mrec',
        creationParamsCodec: StandardMessageCodec(),
      ),
    );
  }
}
