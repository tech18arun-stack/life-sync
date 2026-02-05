import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/notification_service.dart';
import '../services/gemini_service.dart';
import '../services/security_service.dart';
import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _budgetAlerts = true;
  bool _reminderAlerts = true;
  bool _savingsGoalAlerts = true;
  String _currency = 'INR';

  // Security
  bool _appLockEnabled = false;
  bool _biometricEnabled = false;

  // AI Features
  bool _aiEnabled = false;
  String _apiKey = '';
  bool _apiKeyValid = false;
  bool _isValidating = false;
  final _apiKeyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Initialize Security
    await SecurityService().initialize();

    final geminiService = Provider.of<GeminiService>(context, listen: false);
    // Initialize is handled by provider creation in main, but doesn't hurt to ensure
    if (!geminiService.isInitialized) {
      await geminiService.initialize();
    }

    final apiKey = await geminiService.getApiKey();
    final aiEnabled = await geminiService.isAIEnabled();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _budgetAlerts = prefs.getBool('budgetAlerts') ?? true;
      _reminderAlerts = prefs.getBool('reminderAlerts') ?? true;
      _savingsGoalAlerts = prefs.getBool('savingsGoalAlerts') ?? true;
      _currency = prefs.getString('currency') ?? 'INR';
      _apiKey = apiKey ?? '';
      _aiEnabled = aiEnabled && (apiKey != null && apiKey.isNotEmpty);
      _apiKeyValid = apiKey != null && apiKey.isNotEmpty;

      _appLockEnabled = SecurityService().isAppLockEnabled;
      _biometricEnabled = SecurityService().isBiometricEnabled;
    });

    if (_apiKey.isNotEmpty) {
      _apiKeyController.text = _maskApiKey(_apiKey);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSettingContainer(
            context,
            children: [
              _buildSettingTile(
                context,
                title: 'Dark Mode',
                subtitle: themeProvider.isDarkMode ? 'Enabled' : 'Disabled',
                icon: themeProvider.isDarkMode
                    ? FontAwesomeIcons.moon
                    : FontAwesomeIcons.sun,
                trailing: Switch(
                  value: themeProvider.isDarkMode,
                  onChanged: (value) async {
                    await themeProvider.setTheme(value);
                    await _saveSetting('darkMode', value);
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                title: 'Currency',
                subtitle: _getCurrencySymbol(_currency),
                icon: FontAwesomeIcons.indianRupeeSign,
                onTap: () => _showCurrencyDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          _buildSettingContainer(
            context,
            children: [
              _buildSettingTile(
                context,
                title: 'Enable Notifications',
                subtitle: _notificationsEnabled ? 'Enabled' : 'Disabled',
                icon: FontAwesomeIcons.bell,
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: (value) async {
                    setState(() => _notificationsEnabled = value);
                    _saveSetting('notificationsEnabled', value);
                    final notificationService = NotificationService();
                    if (value) {
                      await notificationService.initialize();
                    }
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ),
              if (_notificationsEnabled) ...[
                _buildDivider(context),
                _buildSettingTile(
                  context,
                  title: 'Budget Alerts',
                  subtitle: _budgetAlerts
                      ? 'Get notified when over budget'
                      : 'Budget alerts disabled',
                  icon: FontAwesomeIcons.piggyBank,
                  trailing: _buildMiniSwitch(_budgetAlerts, (val) {
                    setState(() => _budgetAlerts = val);
                    _saveSetting('budgetAlerts', val);
                  }, AppTheme.warningColor),
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context,
                  title: 'Bill Reminders',
                  subtitle: _reminderAlerts
                      ? 'Get notified for upcoming bills'
                      : 'Reminder alerts disabled',
                  icon: FontAwesomeIcons.clockRotateLeft,
                  trailing: _buildMiniSwitch(_reminderAlerts, (val) {
                    setState(() => _reminderAlerts = val);
                    _saveSetting('reminderAlerts', val);
                  }, AppTheme.errorColor),
                ),
                _buildDivider(context),
                _buildSettingTile(
                  context,
                  title: 'Savings Goal Alerts',
                  subtitle: _savingsGoalAlerts
                      ? 'Get notified on goal completion'
                      : 'Savings alerts disabled',
                  icon: FontAwesomeIcons.bullseye,
                  trailing: _buildMiniSwitch(_savingsGoalAlerts, (val) {
                    setState(() => _savingsGoalAlerts = val);
                    _saveSetting('savingsGoalAlerts', val);
                  }, AppTheme.successColor),
                ),
              ],
            ],
          ),

          const SizedBox(height: 24),

          // AI Features Section
          _buildSectionHeader(context, 'AI Features'),
          _buildAIFeaturesSection(context, isDark),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader(context, 'Privacy & Security'),
          _buildSettingContainer(
            context,
            children: [
              _buildSettingTile(
                context,
                title: 'App Lock',
                subtitle: 'Require authentication to open app',
                icon: FontAwesomeIcons.lock,
                trailing: Switch(
                  value: _appLockEnabled,
                  onChanged: (value) async {
                    if (value) {
                      // Verify identity before enabling
                      final success = await SecurityService().authenticate();
                      if (success) {
                        await SecurityService().setAppLock(true);
                        setState(() => _appLockEnabled = true);
                      }
                    } else {
                      // Verify identity before disabling
                      final success = await SecurityService().authenticate();
                      if (success) {
                        await SecurityService().setAppLock(false);
                        setState(() => _appLockEnabled = false);
                      }
                    }
                  },
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.primaryColor,
                ),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                title: 'Biometric Lock',
                subtitle: 'Enable fingerprint/face unlock',
                icon: FontAwesomeIcons.fingerprint,
                trailing: Switch(
                  value: _biometricEnabled,
                  onChanged: _appLockEnabled
                      ? (value) async {
                          await SecurityService().setBiometric(value);
                          setState(() => _biometricEnabled = value);
                        }
                      : null, // Disable if App Lock is off
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.accentColor,
                ),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                title: 'Data Privacy',
                subtitle: 'All data stored locally on your device',
                icon: FontAwesomeIcons.shieldHalved,
                onTap: () {
                  _showSimpleDialog(
                    context,
                    'Data Privacy',
                    '✓ All your data is stored locally on your device\n'
                        '✓ No data is sent to external servers\n'
                        '✓ You have full control over your information\n'
                        '✓ Backups are saved to locations of your choice\n'
                        '✓ We do not collect any personal information',
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingContainer(
            context,
            children: [
              _buildSettingTile(
                context,
                title: 'Version',
                subtitle: '1.0.0 (Latest)',
                icon: FontAwesomeIcons.codeBranch,
                onTap: () {
                  _showUpdateDialog(context);
                },
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                title: 'Privacy Policy',
                subtitle: 'Read our privacy policy',
                icon: FontAwesomeIcons.fileContract,
                onTap: () => _showSimpleDialog(
                  context,
                  'Privacy Policy',
                  'LifeSync Privacy Policy\n\nYour privacy is important to us. We store all data locally...',
                ),
              ),
              _buildDivider(context),
              _buildSettingTile(
                context,
                title: 'Rate Us',
                subtitle: 'Rate us on Play Store',
                icon: FontAwesomeIcons.star,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Thank you for your support! ❤️',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 40),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _showLogoutDialog(context, authProvider),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                  foregroundColor: AppTheme.errorColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  side: BorderSide(
                    color: AppTheme.errorColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout_rounded),
                    const SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // App Info Footer
          Center(
            child: Column(
              children: [
                Text(
                  'LifeSync',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textTertiary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Plan • Track • Achieve',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textTertiary.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingContainer(
    BuildContext context, {
    required List<Widget> children,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.cardColor : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.backgroundColor : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, size: 18, color: AppTheme.textSecondary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: AppTheme.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: AppTheme.textTertiary.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[200],
      indent: 64,
    );
  }

  Widget _buildMiniSwitch(
    bool value,
    Function(bool) onChanged,
    Color activeColor,
  ) {
    return Transform.scale(
      scale: 0.8,
      child: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.white,
        activeTrackColor: activeColor,
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Logout',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to logout?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Currency',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildCurrencyOption('INR', '₹ Indian Rupee'),
            _buildCurrencyOption('USD', '\$ US Dollar'),
            _buildCurrencyOption('EUR', '€ Euro'),
            _buildCurrencyOption('GBP', '£ British Pound'),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyOption(String code, String name) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        name,
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _currency == code
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.check,
          color: _currency == code ? AppTheme.primaryColor : Colors.transparent,
          size: 20,
        ),
      ),
      onTap: () {
        setState(() => _currency = code);
        _saveSetting('currency', code);
        Navigator.pop(context);
      },
    );
  }

  String _getCurrencySymbol(String code) {
    switch (code) {
      case 'INR':
        return '₹ Indian Rupee';
      case 'USD':
        return '\$ US Dollar';
      case 'EUR':
        return '€ Euro';
      case 'GBP':
        return '£ British Pound';
      default:
        return '₹ Indian Rupee';
    }
  }

  Widget _buildAIFeaturesSection(BuildContext context, bool isDark) {
    return _buildSettingContainer(
      context,
      children: [
        _buildSettingTile(
          context,
          title: 'Enable AI Insights',
          subtitle: _aiEnabled
              ? 'AI features are active'
              : 'AI features are disabled',
          icon: FontAwesomeIcons.brain,
          trailing: Switch(
            value: _aiEnabled,
            onChanged: _apiKeyValid
                ? (value) async {
                    setState(() => _aiEnabled = value);
                    if (!context.mounted) return;
                    await Provider.of<GeminiService>(
                      context,
                      listen: false,
                    ).setAIEnabled(value);
                  }
                : null,
            activeThumbColor: Colors.white,
            activeTrackColor: AppTheme.accentColor,
          ),
        ),
        _buildDivider(context),
        _buildSettingTile(
          context,
          title: 'Gemini API Key',
          subtitle: _apiKey.isEmpty
              ? 'Not configured - Tap to add'
              : _maskApiKey(_apiKey),
          icon: FontAwesomeIcons.key,
          onTap: () => _showApiKeyDialog(),
        ),
        if (_apiKey.isNotEmpty) ...[
          _buildDivider(context),
          _buildSettingTile(
            context,
            title: 'Test AI Connection',
            subtitle: 'Verify your API key is working',
            icon: FontAwesomeIcons.flask,
            onTap: _isValidating ? null : _validateApiKey,
            trailing: _isValidating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
        ],
      ],
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: _apiKey);
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.key,
                color: AppTheme.accentColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Gemini API Key',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your Gemini API key to enable AI-powered budget tips and insights.',
                style: GoogleFonts.inter(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: !isVisible,
                style: GoogleFonts.inter(),
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your API key',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      isVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setDialogState(() => isVisible = !isVisible);
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                if (newKey.isEmpty) return;
                Navigator.pop(context);

                // Save
                final geminiService = Provider.of<GeminiService>(
                  context,
                  listen: false,
                );
                final isValid = await geminiService.saveApiKey(newKey);
                setState(() {
                  _apiKey = newKey;
                  _apiKeyValid = isValid;
                  if (isValid) {
                    _aiEnabled = true;
                    geminiService.setAIEnabled(true);
                  }
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isValid ? 'API Key Saved' : 'Invalid API Key',
                        style: GoogleFonts.inter(),
                      ),
                      backgroundColor: isValid
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Save',
                style: GoogleFonts.inter(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateApiKey() async {
    setState(() => _isValidating = true);
    try {
      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final isValid = await geminiService.validateApiKey();
      setState(() {
        _apiKeyValid = isValid;
        _isValidating = false;
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid ? 'Valid API Key!' : 'Invalid API Key',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: isValid
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isValidating = false);
    }
  }

  String _maskApiKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  void _showSimpleDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(content, style: GoogleFonts.inter(height: 1.5)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  void _showUpdateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'What\'s New',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 1.0.0',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '• New Premium Design\n• Enhanced Reports\n• Dark Mode Improvements',
                style: GoogleFonts.inter(height: 1.5),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }
}
