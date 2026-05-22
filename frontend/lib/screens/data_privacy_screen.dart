import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DataPrivacyScreen extends StatelessWidget {
  const DataPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    final List<Map<String, dynamic>> privacyFeatures = [
      {
        'title': 'Local Storage',
        'desc': 'All your financial, health, and personal data is encrypted and stored strictly on your device.',
        'icon': Icons.storage_rounded,
        'color': AppTheme.primaryColor,
      },
      {
        'title': 'Zero Cloud Access',
        'desc': 'We do not have servers to access or read your private data. Your information is your property.',
        'icon': Icons.cloud_off_rounded,
        'color': AppTheme.errorColor,
      },
      {
        'title': 'Offline-First Philosophy',
        'desc': 'The app works fully without internet. We only use connectivity to fetch config or for premium features.',
        'icon': Icons.wifi_off_rounded,
        'color': AppTheme.successColor,
      },
      {
        'title': 'Biometric Security',
        'desc': 'Enable fingerprint or face unlock in Settings to add a second layer of defense to your personal records.',
        'icon': Icons.fingerprint_rounded,
        'color': AppTheme.accentColor,
      },
      {
        'title': 'Full Data Portability',
        'desc': 'You can export your database at any time and move it between devices effortlessly.',
        'icon': Icons.import_export_rounded,
        'color': AppTheme.warningColor,
      },
    ];

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.white,
      appBar: AppBar(
        title: Text('Data Privacy', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(FontAwesomeIcons.shieldHalved, size: 64, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Your Data is Yours',
              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'At LifeSync, we believe that your personal data should never be on a third-party server. Here is how we protect your privacy.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 40),
            ...privacyFeatures.map((feature) => _buildPrivacyRow(context, feature, isDark)),
            const SizedBox(height: 40),
            _buildEncryptedBanner(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyRow(BuildContext context, Map<String, dynamic> feature, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (feature['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(feature['icon'] as IconData, color: feature['color'] as Color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature['title'] as String,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  feature['desc'] as String,
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptedBanner(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppTheme.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'All data is encrypted with AES-256 standard locally on your mobile device storage.',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}
