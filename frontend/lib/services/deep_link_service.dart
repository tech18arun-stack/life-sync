import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'appwrite_service.dart';

/// Deep Link Service for handling app links and auth redirects
/// 
/// Updated for Appwrite authentication flow.
class DeepLinkService {
  static const _channel = MethodChannel('deep_links');
  static final AppwriteService _appwrite = AppwriteService();

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

    // Note: Appwrite handles auth state differently than Supabase
    // Auth state is managed through the AuthService
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

      // Handle Appwrite auth redirects if needed
      if (uri.queryParameters.containsKey('userId') ||
          uri.queryParameters.containsKey('secret')) {
        await _handleAppwriteAuthRedirect(uri);
      }
    } catch (e) {
      debugPrint('Error handling deep link: $e');
    }
  }

  static Future<void> _handleAppwriteAuthRedirect(Uri uri) async {
    try {
      // Appwrite handles authentication through sessions
      // This method can be extended to handle specific Appwrite auth flows
      debugPrint('Handling Appwrite auth redirect: ${uri.toString()}');
      
      // The auth state will be automatically managed by AuthService
      // You can add custom logic here if needed
    } catch (e) {
      debugPrint('Error handling Appwrite auth redirect: $e');
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