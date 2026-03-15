import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

/// Banner Ad Widget for Start.io
///
/// Displays a persistent banner ad at the bottom of the screen.
/// Banner ads generate continuous impressions without user interaction.
///
/// Usage:
/// ```dart
/// StartIOBannerAd() // Add at bottom of Scaffold
/// ```
class StartIOBannerAd extends StatefulWidget {
  const StartIOBannerAd({super.key});

  @override
  State<StartIOBannerAd> createState() => _StartIOBannerAdState();
}

class _StartIOBannerAdState extends State<StartIOBannerAd> {
  static const MethodChannel _channel = MethodChannel('startio_ads');
  bool _isLoaded = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    try {
      if (kDebugMode) {
        print('📢 [Start.io] Loading banner ad...');
      }
      // Note: Start.io banner is auto-managed via XML layout
      // This is a placeholder for future native banner integration
      setState(() {
        _isLoaded = true;
      });
      if (kDebugMode) {
        print('✅ [Start.io] Banner ad loaded');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [Start.io] Banner ad error: $e');
      }
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || !_isLoaded) {
      return const SizedBox.shrink();
    }

    // Placeholder banner container
    // In production, this will be replaced with native Start.io banner view
    return Container(
      height: 50,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          top: BorderSide(
            color: Colors.grey.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: Text(
          'Advertisement',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
