import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';
import '../services/razorpay_service.dart';
import '../services/config_service.dart';
import 'settings_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final configService = ConfigService();

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : const Color(0xFFF7F9FC),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // — Gradient App Bar / Profile Hero —
                SliverAppBar(
                  expandedHeight: 260,
                  pinned: true,
                  backgroundColor: AppTheme.primaryColor,
                  leading: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            // Avatar
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                  width: 3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.25),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 44,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name.substring(0, 1).toUpperCase()
                                      : 'U',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 38,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Name
                            Text(
                              user.name,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            // Email
                            Text(
                              user.email,
                              style: GoogleFonts.inter(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            // Premium / Free badge
                            _buildStatusBadge(user.isPremiumActive),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 600.ms, curve: Curves.easeOut),
                  ),
                ),

                // — Body Cards —
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Premium Card
                          _buildPremiumCard(
                                context,
                                authProvider,
                                user,
                                configService,
                              )
                              .animate(delay: 100.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOutQuad),
                          const SizedBox(height: 20),

                          // Profile Details
                          _buildSectionLabel(
                            'Profile Details',
                          ).animate(delay: 150.ms).fadeIn(),
                          const SizedBox(height: 12),
                          _buildInfoCard(context, isDark, [
                                _InfoRow(
                                  icon: Icons.person_outline,
                                  label: 'Full Name',
                                  value: user.name,
                                ),
                                _InfoRow(
                                  icon: Icons.email_outlined,
                                  label: 'Email',
                                  value: user.email,
                                ),
                                _InfoRow(
                                  icon: Icons.phone_outlined,
                                  label: 'Phone',
                                  value: (user.phone?.isNotEmpty == true)
                                      ? user.phone!
                                      : 'Not provided',
                                ),
                                _InfoRow(
                                  icon: Icons.manage_accounts_outlined,
                                  label: 'Account Type',
                                  value: user.userType == 'admin'
                                      ? 'Admin / Owner'
                                      : 'Family Member',
                                ),
                                _InfoRow(
                                  icon: Icons.verified_outlined,
                                  label: 'Status',
                                  value: user.isActive ? 'Active' : 'Inactive',
                                  valueColor: user.isActive
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                                if (user.createdAt != null)
                                  _InfoRow(
                                    icon: Icons.calendar_today_outlined,
                                    label: 'Member Since',
                                    value: DateFormat(
                                      'dd MMM yyyy',
                                    ).format(user.createdAt!),
                                  ),
                              ])
                              .animate(delay: 200.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOutQuad),

                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            'Preferences',
                          ).animate(delay: 250.ms).fadeIn(),
                          const SizedBox(height: 12),
                          _buildInfoCard(context, isDark, [
                                _InfoRow(
                                  icon: Icons.settings_rounded,
                                  label: 'App Settings',
                                  value: 'Notifications, Dark Mode, AI & more',
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SettingsScreen(),
                                    ),
                                  ),
                                ),
                              ])
                              .animate(delay: 300.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOutQuad),

                          const SizedBox(height: 20),
                          _buildSectionLabel(
                            'Subscription',
                          ).animate(delay: 350.ms).fadeIn(),
                          const SizedBox(height: 12),
                          _buildSubscriptionCard(
                                context,
                                isDark,
                                user,
                                authProvider,
                                configService,
                              )
                              .animate(delay: 400.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, curve: Curves.easeOutQuad),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }

  // ─── Premium Status Badge ────────────────────────────────────────────────
  Widget _buildStatusBadge(bool isPremium) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isPremium
            ? const Color(0xFFFFD700).withOpacity(0.2)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? const Color(0xFFFFD700).withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(
            isPremium ? FontAwesomeIcons.crown : FontAwesomeIcons.user,
            color: isPremium ? const Color(0xFFFFD700) : Colors.white,
            size: 14,
          ),
          const SizedBox(width: 6),
          Text(
            isPremium ? 'Premium Member' : 'Free Plan',
            style: GoogleFonts.inter(
              color: isPremium ? const Color(0xFFFFD700) : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Premium Upgrade / Status Card ─────────────────────────────────────
  Widget _buildPremiumCard(
    BuildContext context,
    AuthProvider authProvider,
    dynamic user,
    ConfigService configService,
  ) {
    final isPremium = user.isPremiumActive as bool;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: isPremium
            ? const LinearGradient(
                colors: [Color(0xFF8E54E9), Color(0xFF4776E6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : const LinearGradient(
                colors: [Color(0xFFFF8C00), Color(0xFFFF5C00)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isPremium ? AppTheme.primaryColor : Colors.orange)
                .withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isPremium
          ? _buildPremiumActiveContent(user)
          : _buildUpgradeContent(context, authProvider, user, configService),
    );
  }

  Widget _buildPremiumActiveContent(dynamic user) {
    final expiry = user.premiumExpiryDate as DateTime?;
    final daysLeft = expiry != null
        ? expiry.difference(DateTime.now()).inDays
        : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const FaIcon(
                FontAwesomeIcons.crown,
                color: Color(0xFFFFD700),
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Active',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'All features unlocked ✨',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (expiry != null) ...[
          Row(
            children: [
              _buildPremiumStat(
                'Expires',
                DateFormat('dd MMM yyyy').format(expiry),
              ),
              const SizedBox(width: 20),
              _buildPremiumStat('Days Left', '$daysLeft days'),
            ],
          ),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Ad-free experience enabled',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpgradeContent(
    BuildContext context,
    AuthProvider authProvider,
    dynamic user,
    ConfigService configService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const FaIcon(
                FontAwesomeIcons.crown,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Upgrade to Premium',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    'Remove ads & unlock all features',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Feature bullets
        _buildFeatureBullet('No ads on any screen'),
        _buildFeatureBullet('Unlimited AI advisor chats'),
        _buildFeatureBullet('Advanced analytics & reports'),
        _buildFeatureBullet('Priority family features'),
        const SizedBox(height: 20),
        _buildPlanCard(
          context,
          title: 'Premium Basic',
          subtitle: 'Monthly Billing',
          price: configService.premiumMonthlyCost,
          duration: 'Month',
          days: 30,
          planType: 'premium',
          color: const Color(0xFFFF5C00),
          authProvider: authProvider,
          user: user,
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          title: 'Premium Ultra',
          subtitle: 'Advanced AI & Exclusive Themes',
          price: configService.premiumUltraMonthlyCost,
          duration: 'Month',
          days: 30,
          planType: 'ultra',
          color: const Color(0xFF8B5CF6),
          authProvider: authProvider,
          user: user,
          isPopular: true,
        ),
        const SizedBox(height: 12),
        _buildPlanCard(
          context,
          title: 'Premium Yearly',
          subtitle: 'Save 50% with Yearly Billing',
          price: configService.premiumYearlyCost,
          duration: 'Year',
          days: 365,
          planType: 'premium',
          color: const Color(0xFF10B981),
          authProvider: authProvider,
          user: user,
        ),
      ],
    );
  }

  Widget _buildPlanCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required double price,
    required String duration,
    required int days,
    required Color color,
    required AuthProvider authProvider,
    required dynamic user,
    String planType = 'premium',
    bool isPopular = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isPopular ? Border.all(color: color, width: 2) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (isPopular) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'POPULAR',
                              style: TextStyle(
                                color: color,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                  Text(
                    '/$duration',
                    style: GoogleFonts.inter(
                      color: Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                final razorpay = RazorpayService();
                razorpay.initialize();
                razorpay.openPaymentSheet(
                  amount: price,
                  name: 'LifeSync $title',
                  description: '$title Subscription',
                  email: user.email,
                  contact: user.phone ?? '',
                  durationDays: days,
                  planType: planType,
                  onSuccess: () async {
                    await authProvider.refreshUser();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('🎉 Welcome to LifeSync $title!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                      setState(() {});
                    }
                  },
                  onError: (msg) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ Payment failed: $msg'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  },
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Subscribe Now',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureBullet(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 15),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Profile Info Card ──────────────────────────────────────────────────
  Widget _buildInfoCard(
    BuildContext context,
    bool isDark,
    List<_InfoRow> rows,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(rows.length, (i) {
          final row = rows[i];
          return Column(
            children: [
              InkWell(
                onTap: row.onTap,
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          row.icon,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppTheme.textTertiary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color:
                                    row.valueColor ??
                                    (isDark
                                        ? Colors.white
                                        : const Color(0xFF1A1A1A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (row.onTap != null)
                        Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: AppTheme.textTertiary.withOpacity(0.4),
                        ),
                    ],
                  ),
                ),
              ),
              if (i < rows.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey[100],
                  indent: 58,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Subscription Card ──────────────────────────────────────────────────
  Widget _buildSubscriptionCard(
    BuildContext context,
    bool isDark,
    dynamic user,
    AuthProvider authProvider,
    ConfigService configService,
  ) {
    final isPremium = user.isPremiumActive as bool;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.crown,
                  size: 20,
                  color: isPremium
                      ? const Color(0xFFFFD700)
                      : AppTheme.textTertiary,
                ),
                const SizedBox(width: 12),
                Text(
                  isPremium ? 'Premium Plan' : 'Free Plan',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPremium
                        ? AppTheme.successColor.withOpacity(0.15)
                        : AppTheme.textTertiary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isPremium ? 'ACTIVE' : 'FREE',
                    style: GoogleFonts.inter(
                      color: isPremium
                          ? AppTheme.successColor
                          : AppTheme.textTertiary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100],
              height: 1,
            ),
            const SizedBox(height: 16),
            if (isPremium) ...[
              _buildSubRow(
                'Billing',
                'Monthly @ ₹${configService.premiumMonthlyCost.toStringAsFixed(0)}',
              ),
              const SizedBox(height: 10),
              _buildSubRow(
                'Expires On',
                user.premiumExpiryDate != null
                    ? DateFormat('dd MMMM yyyy').format(user.premiumExpiryDate!)
                    : 'N/A',
              ),
              const SizedBox(height: 10),
              _buildSubRow('Ads', '✅ Disabled'),
              const SizedBox(height: 10),
              _buildSubRow('AI Advisor', '✅ Unlimited'),
              const SizedBox(height: 10),
              _buildSubRow('Analytics', '✅ Full Access'),
              const SizedBox(height: 20),
              // Renew button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    final razorpay = RazorpayService();
                    razorpay.initialize();
                    razorpay.openPaymentSheet(
                      amount: configService.premiumMonthlyCost,
                      name: 'LifeSync Premium',
                      description: 'Premium Renewal',
                      email: user.email,
                      contact: user.phone ?? '',
                      onSuccess: () async {
                        await authProvider.refreshUser();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                '🎉 Premium renewed for another month!',
                              ),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                          setState(() {});
                        }
                      },
                      onError: (msg) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment failed: $msg'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
                  label: Text(
                    'Renew Subscription',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ] else ...[
              _buildSubRow('Billing', 'Free'),
              const SizedBox(height: 10),
              _buildSubRow('Ads', '❌ Shown (upgrade to remove)'),
              const SizedBox(height: 10),
              _buildSubRow('AI Advisor', '⚠️ Limited'),
              const SizedBox(height: 10),
              _buildSubRow('Analytics', '⚠️ Basic only'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final razorpay = RazorpayService();
                    razorpay.initialize();
                    razorpay.openPaymentSheet(
                      amount: configService.premiumMonthlyCost,
                      name: 'LifeSync Premium',
                      description: 'Monthly Premium Subscription',
                      email: user.email,
                      contact: user.phone ?? '',
                      onSuccess: () async {
                        await authProvider.refreshUser();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('🎉 Welcome to Premium!'),
                              backgroundColor: AppTheme.successColor,
                            ),
                          );
                          setState(() {});
                        }
                      },
                      onError: (msg) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Payment failed: $msg'),
                              backgroundColor: AppTheme.errorColor,
                            ),
                          );
                        }
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const FaIcon(FontAwesomeIcons.crown, size: 14),
                  label: Text(
                    'Upgrade to Premium — ₹${configService.premiumMonthlyCost.toStringAsFixed(0)}/mo',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textTertiary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        color: AppTheme.primaryColor,
        fontWeight: FontWeight.bold,
        fontSize: 12,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });
}
