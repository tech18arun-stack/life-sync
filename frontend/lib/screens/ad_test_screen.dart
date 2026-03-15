import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/startio_ads.dart';

/// Start.io Ad Testing Screen
///
/// Use this screen to test all ad types and verify integration.
/// Access this screen from Settings → Test Ads (debug only)
class AdTestScreen extends StatelessWidget {
  const AdTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Test Start.io Ads',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.blue.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Testing Information',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Test ads on a real device. Ads may not show in emulator.\n'
                    'New accounts need 24-72 hours for approval.',
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Test Buttons
            _buildTestButton(
              context,
              title: '📢 Test Interstitial Ad',
              subtitle: 'Full-screen ad that appears between actions',
              icon: Icons.ads_click,
              onTap: () async {
                await StartIOAds.showInterstitial();
                _showResultSnackbar(context, 'Interstitial Ad Requested');
              },
            ),

            _buildTestButton(
              context,
              title: '🎬 Test Rewarded Video',
              subtitle: 'Video ad that unlocks premium features',
              icon: Icons.play_circle,
              onTap: () async {
                final success = await StartIOAds.showRewarded();
                _showResultSnackbar(
                  context,
                  success
                      ? 'Rewarded Video Shown'
                      : 'Failed to show rewarded video',
                );
              },
            ),

            _buildTestButton(
              context,
              title: '🚀 Test Splash Ad',
              subtitle: 'Ad shown on app launch (use sparingly)',
              icon: Icons.rocket_launch,
              onTap: () async {
                await StartIOAds.showSplash();
                _showResultSnackbar(context, 'Splash Ad Requested');
              },
            ),

            const Spacer(),

            // Debug Info
            _buildDebugInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF6C63FF), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🔍 Debug Checklist',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildCheckItem('✅ App ID: 201957244'),
          _buildCheckItem('✅ SDK Version: 4.10.8'),
          _buildCheckItem('✅ Internet Permission: Granted'),
          _buildCheckItem('✅ Real Device Required'),
          const SizedBox(height: 8),
          Text(
            'Check Android Studio logcat for "Start.io" logs',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 14, color: Colors.green),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(fontSize: 12)),
        ],
      ),
    );
  }

  void _showResultSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }
}
