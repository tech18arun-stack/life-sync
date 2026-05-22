import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'auth_service.dart';
import 'config_service.dart';

/// Start.io (StartApp) Ads Service
///
/// Provides interstitial, splash, banner, and rewarded ad functionality.
///
/// ⭐ PREMIUM: All ads are automatically disabled for premium users.
/// 🔧 CONFIG : Ads can also be globally disabled via config (adsEnabled flag).
///
/// Single source-of-truth: _shouldShowAds() gate used by every ad method.
class StartIOAds {
  static const MethodChannel _channel = MethodChannel('startio_ads');

  /// Returns true when ads SHOULD be shown.
  static bool _shouldShowAds([BuildContext? context]) {
    final config = ConfigService();
    if (!config.adsEnabled || !config.startioEnabled) return false;

    // Use AuthService singleton directly for more reliable premium check (no context needed)
    final authService = AuthService();
    
    // ⭐ PROACTIVE: Suppress ads if user state is unknown (e.g. still initializing)
    // or if the user is verified as Premium.
    if (authService.currentUser == null || authService.currentUser?.isPremiumActive == true) {
      if (kDebugMode && context != null && authService.currentUser?.isPremiumActive == true) {
        debugPrint('⭐ [Start.io] Ads suppressed via AuthService for Premium User: ${authService.currentUser?.email}');
      }
      return false;
    }

    return true;
  }

  static Future<void> initialize(String appId) async {
    // If provided ID is empty, use a hardcoded fallback (manifest default)
    final effectiveId = appId.isEmpty ? '201957244' : appId;
    
    try {
      await _channel.invokeMethod('initStartio', {
        'appId': effectiveId,
        'testMode': kDebugMode, // Still use debug/test mode based on build variant for safety
      });
    } catch (e) {
      debugPrint('❌ [Start.io] Initialization failed: $e');
    }
  }

  // ─── Interstitial ──────────────────────────────────────────────────────────
  /// Best used at natural break points (after add/delete actions).
  static Future<void> showInterstitial([BuildContext? context]) async {
    if (!_shouldShowAds(context)) {
      if (kDebugMode) print('⭐ [Start.io] Interstitial suppressed');
      return;
    }
    try {
      if (kDebugMode) print('📢 [Start.io] Requesting interstitial...');
      await _channel.invokeMethod('showInterstitial');
    } on PlatformException catch (e) {
      if (kDebugMode) print('❌ [Start.io] Interstitial failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('❌ [Start.io] Error: $e');
    }
  }

  // ─── Video Interstitial ────────────────────────────────────────────────────
  static Future<void> showVideoInterstitial([BuildContext? context]) async {
    if (!_shouldShowAds(context)) {
      if (kDebugMode) print('⭐ [Start.io] Video interstitial suppressed');
      return;
    }
    try {
      if (kDebugMode) print('📢 [Start.io] Requesting video interstitial...');
      await _channel.invokeMethod('showVideoInterstitial');
    } on PlatformException catch (e) {
      if (kDebugMode) print('❌ [Start.io] Video interstitial failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('❌ [Start.io] Error: $e');
    }
  }

  // ─── Splash ────────────────────────────────────────────────────────────────
  /// Show once per session on app launch.
  static Future<void> showSplash([BuildContext? context]) async {
    if (!_shouldShowAds(context)) {
      if (kDebugMode) print('⭐ [Start.io] Splash suppressed');
      return;
    }
    try {
      if (kDebugMode) print('📢 [Start.io] Requesting splash ad...');
      await _channel.invokeMethod('showSplash');
      if (kDebugMode) print('✅ [Start.io] Splash displayed');
    } on PlatformException catch (e) {
      if (kDebugMode) print('❌ [Start.io] Splash failed: ${e.message}');
    } catch (e) {
      if (kDebugMode) print('❌ [Start.io] Error: $e');
    }
  }

  // ─── Rewarded ──────────────────────────────────────────────────────────────
  /// Returns true if reward granted (either watched ad or premium user).
  static Future<bool> showRewarded([BuildContext? context]) async {
    if (!_shouldShowAds(context)) {
      if (kDebugMode) print('⭐ [Start.io] Rewarded suppressed – granting access');
      return true; // Grant immediately for premium / when ads disabled
    }
    try {
      if (kDebugMode) print('📢 [Start.io] Requesting rewarded video...');
      final bool? result = await _channel.invokeMethod('showRewarded');
      return result ?? false;
    } on PlatformException catch (e) {
      if (kDebugMode) print('❌ [Start.io] Rewarded failed: ${e.message}');
      return false;
    } catch (e) {
      if (kDebugMode) print('❌ [Start.io] Error: $e');
      return false;
    }
  }

  // ─── Return Ad ─────────────────────────────────────────────────────────────
  static Future<void> showReturnAd([BuildContext? context]) async {
    if (!_shouldShowAds(context)) return;
    try {
      if (kDebugMode) print('📢 [Start.io] Enabling return ads...');
      await _channel.invokeMethod('showReturnAd');
    } catch (e) {
      if (kDebugMode) print('❌ [Start.io] Return ad failed: $e');
    }
  }
}

// ─── Banner Ad Widget ──────────────────────────────────────────────────────────
/// Persistent bottom banner ad.
/// Reactively hidden when user subscribes to premium (listen: true).
/// Also hidden when global adsEnabled / startioEnabled flags are false.
class StartioBanner extends StatelessWidget {
  const StartioBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final config = ConfigService();
    if (!config.adsEnabled || !config.startioEnabled) {
      return const SizedBox.shrink();
    }

    // listen: true → rebuilds immediately when premium status changes
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null || auth.currentUser?.isPremiumActive == true) {
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

// ─── MREC Ad Widget ────────────────────────────────────────────────────────────
/// 300×250 inline ad for lists.
/// Reactively hidden for premium users (listen: true).
class StartioMrec extends StatelessWidget {
  const StartioMrec({super.key});

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return const SizedBox.shrink();
    }

    final config = ConfigService();
    if (!config.adsEnabled || !config.startioEnabled) {
      return const SizedBox.shrink();
    }

    // listen: true → rebuilds immediately when premium status changes
    final auth = Provider.of<AuthProvider>(context);
    if (auth.currentUser == null || auth.currentUser?.isPremiumActive == true) {
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
