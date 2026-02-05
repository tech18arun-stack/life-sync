import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DeepLinkService {
  static const _channel = MethodChannel('deep_links');

  static Future<void> initDeepLinks() async {
    // Listen for incoming deep links
    if (!kIsWeb) {
      _channel.setMethodCallHandler(_handleMethod);

      // Handle initial deep link if app was opened from a link
      try {
        final initialLink = await _channel.invokeMethod('getInitialLink');
        if (initialLink != null) {
          await _handleDeepLink(initialLink);
        }
      } catch (e) {
        debugPrint('Error getting initial deep link: $e');
      }
    }

    // For web, we handle deep links differently
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters['redirect_type'] != null) {
        await _handleDeepLink(uri.toString());
      }
    }

    // Listen for auth state changes to handle email confirmation redirects
    Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;

        if (event == AuthChangeEvent.passwordRecovery ||
            event == AuthChangeEvent.signedIn ||
            event == AuthChangeEvent.userUpdated ||
            event == AuthChangeEvent.tokenRefreshed) {
          // Handle successful authentication events
          debugPrint('Auth event: $event');

          // If user signed in via email confirmation, navigate to home
          if (event == AuthChangeEvent.signedIn && session != null) {
            // Optionally trigger navigation to home screen
            debugPrint('User successfully authenticated via email confirmation');
          }
        } else if (event == AuthChangeEvent.signedOut) {
          debugPrint('User signed out');
        }
      },
    );
  }

  static Future<void> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case 'onDeepLink':
        await _handleDeepLink(call.arguments);
        break;
    }
  }

  static Future<void> _handleDeepLink(String link) async {
    try {
      final uri = Uri.parse(link);
      
      // Check if this is a Supabase auth redirect
      if (uri.queryParameters.containsKey('redirect_type')) {
        final redirectType = uri.queryParameters['redirect_type'];
        final tokenHash = uri.queryParameters['token_hash'];
        
        if (redirectType != null && tokenHash != null) {
          // Handle email confirmation, password recovery, etc.
          await _handleSupabaseAuthRedirect(redirectType, tokenHash, uri);
        }
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  static Future<void> _handleSupabaseAuthRedirect(
    String redirectType,
    String tokenHash,
    Uri uri,
  ) async {
    try {
      final client = Supabase.instance.client;

      switch (redirectType) {
        case 'signup':
        case 'recovery':
        case 'invite':
          // Verify email or recover password using the token
          final response = await client.auth.verifyOTP(
            type: OtpType.email,
            token: tokenHash,
            email: uri.queryParameters['email'],
          );

          if (response.session != null) {
            debugPrint('Successfully verified email/password recovery');
            // Optionally navigate to home screen or show success message
          }
          break;

        case 'magiclink':
          // Handle magic link authentication
          final response = await client.auth.verifyOTP(
            type: OtpType.magiclink,
            token: tokenHash,
            email: uri.queryParameters['email'],
          );

          if (response.session != null) {
            debugPrint('Successfully authenticated via magic link');
          }
          break;

        default:
          debugPrint('Unknown redirect type: $redirectType');
      }
    } catch (e) {
      debugPrint('Error handling Supabase auth redirect: $e');
    }
  }

  // Method to handle external URL launches (fallback)
  static Future<void> handleExternalUrl(Uri url) async {
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (e) {
      debugPrint('Could not launch $url: $e');
    }
  }
}