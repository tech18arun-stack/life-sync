import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to detect ad-blockers and DNS-based blocking.
class AdBlockDetector {
  static final AdBlockDetector _instance = AdBlockDetector._internal();
  factory AdBlockDetector() => _instance;
  AdBlockDetector._internal();

  bool _isAdBlockerActive = false;
  bool get isAdBlockerActive => _isAdBlockerActive;

  /// Known ad domains to check for resolution
  static const List<String> _adDomains = [
    'googleads.g.doubleclick.net',
    'cdn.startapp.com',
    'info.startapp.com',
    'ads.google.com',
    'pagead2.googlesyndication.com',
  ];

  /// Checks if an ad-blocker is active by attempting to resolve known ad domains.
  Future<bool> checkAdBlocker() async {
    if (kIsWeb) return false; // DNS lookup not directly supported on web via dart:io

    int blockedCount = 0;
    
    for (String domain in _adDomains) {
      try {
        final result = await InternetAddress.lookup(domain).timeout(
          const Duration(seconds: 2),
        );
        if (result.isEmpty || result.first.address.isEmpty) {
          blockedCount++;
        }
      } catch (e) {
        // If lookup fails, it's likely blocked by DNS or a firewall
        blockedCount++;
        if (kDebugMode) {
          print('🚫 [AdBlockDetector] Domain blocked: $domain');
        }
      }
    }

    // If most domains are failing, assume an ad-blocker is active
    _isAdBlockerActive = blockedCount >= 2;
    
    if (kDebugMode && _isAdBlockerActive) {
      print('⚠️ [AdBlockDetector] Ad-blocker or DNS sinkhole detected ($blockedCount failures)');
    }

    return _isAdBlockerActive;
  }

  /// Detects if the current network appears to be using an ad-blocking DNS (e.g. AdGuard DNS)
  Future<bool> checkDnsStatus() async {
    // This is a simplified check. A more robust one might involve 
    // calling a specific API that ad-blockers typically block.
    return await checkAdBlocker();
  }
}
