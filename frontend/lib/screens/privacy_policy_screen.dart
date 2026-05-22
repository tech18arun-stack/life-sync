import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/app_theme.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    const String policyMarkdown = """
# Privacy Policy

**Effective Date: March 20, 2026**

Welcome to **LifeSync**. Your privacy is our top priority. This Privacy Policy explains how we handle your information.

## 1. Data Storage
LifeSync is designed as a **offline-first** application. Most of your personal data, including finances, tasks, and goals, is stored **locally on your device**. We do not have access to this data unless you explicitly choose to backup or sync it through authorized channels.

## 2. Information We Collect
- **Profile Information:** We collect your name and email for account identification and premium status tracking.
- **Financial & Habit Data:** This data remains on your device. We do not transmit your transactions, budgets, or habits to our servers.
- **Device Information:** We may collect basic device info (OS version, model) to improve app performance and troubleshoot bugs.

## 3. Third-Party Services
- **Appwrite:** Used for secure authentication and managing your premium subscription status.
- **Razorpay:** Used for processing secure payments. We do not store your credit card or bank details.
- **Start.io:** Used for displaying non-intrusive advertisements. They may collect limited device IDs to serve relevant ads.
- **Google Generative AI (Gemini):** Used to provide AI insights. Any data sent to the AI is anonymous and used only for generating your requested advice.

## 4. Your Control
You have the right to:
- Access your data anytime via the app.
- Delete your account and all associated data.
- Opt-out of notifications via Settings.

## 5. Security
We implement industry-standard security measures, including App Lock and Biometric encryption (if enabled by you), to protect your local data from unauthorized access.

## 6. Contact Us
If you have any questions about this policy, please contact us at **support@edizo.in**.
""";

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundColor : Colors.white,
      appBar: AppBar(
        title: Text('Privacy Policy', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Markdown(
        data: policyMarkdown,
        styleSheet: MarkdownStyleSheet(
          h1: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          h2: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
          p: GoogleFonts.inter(fontSize: 14, color: isDark ? Colors.white70 : Colors.black54, height: 1.5),
          strong: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
