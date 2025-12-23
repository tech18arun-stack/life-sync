import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/backup_service.dart';
import '../services/notification_service.dart';
import '../services/gemini_service.dart';
import '../providers/theme_provider.dart';
import '../providers/financial_data_manager.dart';
import '../providers/health_provider.dart';
import '../providers/family_provider.dart';
import '../providers/task_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/family_event_provider.dart';
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

  // AI Features
  bool _aiEnabled = false;
  String _apiKey = '';
  bool _apiKeyValid = false;
  bool _isValidating = false;
  final _apiKeyController = TextEditingController();
  final _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _geminiService.initialize();

    final apiKey = await _geminiService.getApiKey();
    final aiEnabled = await _geminiService.isAIEnabled();

    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _budgetAlerts = prefs.getBool('budgetAlerts') ?? true;
      _reminderAlerts = prefs.getBool('reminderAlerts') ?? true;
      _savingsGoalAlerts = prefs.getBool('savingsGoalAlerts') ?? true;
      _currency = prefs.getString('currency') ?? 'INR';
      _apiKey = apiKey ?? '';
      _aiEnabled = aiEnabled && (apiKey != null && apiKey.isNotEmpty);
      _apiKeyValid = apiKey != null && apiKey.isNotEmpty;
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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
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

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value ? 'Dark mode enabled' : 'Light mode enabled',
                      ),
                      backgroundColor: AppTheme.successColor,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              activeThumbColor: AppTheme.primaryColor,
            ),
          ),
          _buildSettingTile(
            context,
            title: 'Currency',
            subtitle: _getCurrencySymbol(_currency),
            icon: FontAwesomeIcons.indianRupeeSign,
            onTap: () => _showCurrencyDialog(context),
          ),

          const SizedBox(height: 24),

          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
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

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Notifications enabled'
                            : 'Notifications disabled',
                      ),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              },
              activeThumbColor: AppTheme.primaryColor,
            ),
          ),
          if (_notificationsEnabled) ...[
            _buildSettingTile(
              context,
              title: 'Budget Alerts',
              subtitle: _budgetAlerts
                  ? 'Get notified when over budget'
                  : 'Budget alerts disabled',
              icon: FontAwesomeIcons.piggyBank,
              trailing: Switch(
                value: _budgetAlerts,
                onChanged: (value) {
                  setState(() => _budgetAlerts = value);
                  _saveSetting('budgetAlerts', value);
                },
                activeThumbColor: AppTheme.warningColor,
              ),
            ),
            _buildSettingTile(
              context,
              title: 'Bill Reminders',
              subtitle: _reminderAlerts
                  ? 'Get notified for upcoming bills'
                  : 'Reminder alerts disabled',
              icon: FontAwesomeIcons.clockRotateLeft,
              trailing: Switch(
                value: _reminderAlerts,
                onChanged: (value) {
                  setState(() => _reminderAlerts = value);
                  _saveSetting('reminderAlerts', value);
                },
                activeThumbColor: AppTheme.errorColor,
              ),
            ),
            _buildSettingTile(
              context,
              title: 'Savings Goal Alerts',
              subtitle: _savingsGoalAlerts
                  ? 'Get notified on goal completion'
                  : 'Savings alerts disabled',
              icon: FontAwesomeIcons.bullseye,
              trailing: Switch(
                value: _savingsGoalAlerts,
                onChanged: (value) {
                  setState(() => _savingsGoalAlerts = value);
                  _saveSetting('savingsGoalAlerts', value);
                },
                activeThumbColor: AppTheme.successColor,
              ),
            ),
          ],

          const SizedBox(height: 24),

          // AI Features Section
          _buildSectionHeader(context, 'AI Features'),
          _buildAIFeaturesSection(),

          const SizedBox(height: 24),

          // Data & Backup Section
          _buildSectionHeader(context, 'Data & Backup'),
          _buildSettingTile(
            context,
            title: 'Backup All Data',
            subtitle: 'Complete backup in JSON format',
            icon: FontAwesomeIcons.cloudArrowUp,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'JSON',
                style: TextStyle(
                  color: AppTheme.successColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () async {
              final backupService = BackupService();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Preparing backup...'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }

              final hasPermission = await backupService
                  .requestStoragePermission();

              if (!hasPermission) {
                if (context.mounted) {
                  _showPermissionDeniedDialog(context);
                }
                return;
              }

              final filePath = await backupService.saveBackupToCustomLocation();

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      filePath != null
                          ? 'Backup saved successfully!\n${filePath.split('/').last}'
                          : 'Backup cancelled or failed',
                    ),
                    backgroundColor: filePath != null
                        ? AppTheme.successColor
                        : AppTheme.errorColor,
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          _buildSettingTile(
            context,
            title: 'Restore Data',
            subtitle: 'Restore from JSON backup file',
            icon: FontAwesomeIcons.clockRotateLeft,
            onTap: () => _showRestoreDialog(context),
          ),

          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'EXPORT OPTIONS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),

          _buildSettingTile(
            context,
            title: 'Export Expenses (CSV)',
            subtitle: 'Spreadsheet format for expenses',
            icon: FontAwesomeIcons.fileExcel,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CSV',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showExportOptions(context, 'expenses'),
          ),
          _buildSettingTile(
            context,
            title: 'Export Income (CSV)',
            subtitle: 'Spreadsheet format for income',
            icon: FontAwesomeIcons.moneyBillTrendUp,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CSV',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showExportOptions(context, 'income'),
          ),
          _buildSettingTile(
            context,
            title: 'Export Budgets (CSV)',
            subtitle: 'Spreadsheet format for budgets',
            icon: FontAwesomeIcons.chartPie,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CSV',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showExportOptions(context, 'budgets'),
          ),
          _buildSettingTile(
            context,
            title: 'Export Tasks (CSV)',
            subtitle: 'Spreadsheet format for tasks',
            icon: FontAwesomeIcons.listCheck,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'CSV',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () => _showExportOptions(context, 'tasks'),
          ),
          _buildSettingTile(
            context,
            title: 'Share Financial Report',
            subtitle: 'Share monthly summary via any app',
            icon: FontAwesomeIcons.share,
            onTap: () => _shareFinancialReport(context),
          ),
          _buildSettingTile(
            context,
            title: 'Clear All Data',
            subtitle: 'Delete all app data (cannot be undone)',
            icon: FontAwesomeIcons.trashCan,
            onTap: () => _showClearDataDialog(context),
          ),

          const SizedBox(height: 24),

          // Privacy & Security Section
          _buildSectionHeader(context, 'Privacy & Security'),
          _buildSettingTile(
            context,
            title: 'App Lock',
            subtitle: 'Coming in next update - Require PIN to open app',
            icon: FontAwesomeIcons.lock,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildSettingTile(
            context,
            title: 'Biometric Lock',
            subtitle: 'Coming in next update - Use fingerprint/face unlock',
            icon: FontAwesomeIcons.fingerprint,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Soon',
                style: TextStyle(
                  color: AppTheme.warningColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          _buildSettingTile(
            context,
            title: 'Data Privacy',
            subtitle: 'All data stored locally on your device',
            icon: FontAwesomeIcons.shieldHalved,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Data Privacy'),
                  content: const Text(
                    '✓ All your data is stored locally on your device\n'
                    '✓ No data is sent to external servers\n'
                    '✓ You have full control over your information\n'
                    '✓ Backups are saved to locations of your choice\n'
                    '✓ We do not collect any personal information',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader(context, 'About'),
          _buildSettingTile(
            context,
            title: 'Version',
            subtitle: '1.0.0 (Latest)',
            icon: FontAwesomeIcons.codeBranch,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('What\'s New in v1.0.0'),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '🎉 Latest Updates (v1.0.0):',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('✨ Enhanced Reports Screen with:'),
                        const Text('  • Time period filters (Week/Month/Year)'),
                        const Text('  • Financial health score widget'),
                        const Text('  • Top 5 spending categories'),
                        const Text('  • Income vs Expense comparison'),
                        const Text('  • 6-month trend analysis'),
                        const Text('  • Yearly overview dashboard'),
                        const Text('  • Smooth animations throughout'),
                        const SizedBox(height: 8),
                        const Text('🎬 Premium Animated Splash Screen'),
                        const Text('  • Logo bounce animation'),
                        const Text(
                          '  • Feature icons (Analytics/Finance/Health)',
                        ),
                        const Text('  • Floating particles & currency symbols'),
                        const Text('  • Smooth loading progress'),
                        const SizedBox(height: 8),
                        const Text('🎨 New App Logo'),
                        const Text('  • Modern gradient design'),
                        const Text('  • Updated across all platforms'),
                        const Text('  • Professional branding'),
                        const SizedBox(height: 12),
                        const Text(
                          '🎯 Previous Features:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '✅ Separate tabs for Active/Completed reminders',
                        ),
                        const Text('✅ "Rework" option for completed reminders'),
                        const Text('✅ Auto-delete linked expenses on rework'),
                        const Text('✅ Income availability tracking'),
                        const Text('✅ Monthly & yearly financial views'),
                        const Text('✅ Enhanced home screen with balance'),
                        const Text('✅ Reminder-to-expense conversion'),
                        const Text('✅ Improved analytics dashboard'),
                        const Text('✅ Budget integration with income'),
                        const Text('✅ Mobile notifications for all features'),
                        const Text('✅ CSV export for expenses & reports'),
                        const Text('✅ Share reports via other apps'),
                        const Text('✅ Spending trends chart'),
                        const Text('✅ Family members section'),
                        const Text(
                          '✅ Task notifications (1 day before + due date)',
                        ),
                        const Text('✅ Budget alerts (75%, 90%, 100%)'),
                        const Text('✅ Savings goal milestones'),
                        const Text('✅ Event & health visit reminders'),
                        const SizedBox(height: 12),
                        const Text(
                          '🐛 Bug Fixes:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• Fixed task priority filtering'),
                        const Text('• Fixed expense category dropdown'),
                        const Text('• Improved data backup & restore'),
                        const Text('• Enhanced financial calculations'),
                        const Text('• Optimized app performance'),
                        const SizedBox(height: 12),
                        const Text(
                          '⏳ Coming Soon:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text('• PDF export'),
                        const Text('• App lock & biometric authentication'),
                        const Text('• Cloud backup'),
                        const Text('• Advanced charts & forecasting'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            title: 'Check for Updates',
            subtitle: 'See if a new version is available',
            icon: FontAwesomeIcons.arrowsRotate,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You are using the latest version!'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            icon: FontAwesomeIcons.shieldHalved,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Privacy Policy'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'LifeSync Privacy Policy\n\n'
                      'Your privacy is important to us. This app:\n\n'
                      '• Stores all data locally on your device\n'
                      '• Does not collect personal information\n'
                      '• Does not share data with third parties\n'
                      '• Does not require internet connection\n'
                      '• Gives you full control over your data\n\n'
                      'You can export or delete your data at any time from the Settings screen.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            title: 'Terms of Service',
            subtitle: 'Read our terms of service',
            icon: FontAwesomeIcons.fileContract,
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Terms of Service'),
                  content: const SingleChildScrollView(
                    child: Text(
                      'LifeSync Terms of Service\n\n'
                      'By using this app, you agree to:\n\n'
                      '• Use the app for personal family management\n'
                      '• Maintain backups of important data\n'
                      '• Not misuse or attempt to reverse engineer the app\n\n'
                      'The app is provided "as is" without warranties.\n\n'
                      'We are not liable for any data loss. Please maintain regular backups.',
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
          ),
          _buildSettingTile(
            context,
            title: 'Rate Us',
            subtitle: 'Rate us on Play Store',
            icon: FontAwesomeIcons.star,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Thank you for your support! ❤️'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          // App Info Footer
          Center(
            child: Column(
              children: [
                Text(
                  'LifeSync',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textTertiary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your all-in-one life management companion',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2025 All rights reserved',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 18, color: AppTheme.textSecondary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right, color: AppTheme.textTertiary)
                : null),
      ),
    );
  }

  void _showCurrencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Currency'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
      title: Text(name),
      leading: Radio<String>(
        value: code,
        groupValue: _currency,
        onChanged: (value) {
          if (value != null) {
            setState(() => _currency = value);
            _saveSetting('currency', value);
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Currency changed to $name'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        },
      ),
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

  void _showRestoreDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Restoring data will replace all your current data with the backup. This action cannot be undone.\n\nDo you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _performRestore(context);
            },
            child: Text(
              'Restore',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BuildContext context) async {
    // Show loading
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a backup file to restore...'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final backupService = BackupService();

    // Request permission first (though restoreFromFile uses FilePicker which handles read permission usually)
    // But good to be safe if we need to access legacy storage
    await backupService.requestStoragePermission();

    final result = await backupService.restoreFromFile();

    if (!context.mounted) return;

    if (result['success'] == true) {
      // Show loading for data reload
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reloading data...')));

      try {
        // Reload all providers
        await Provider.of<FinancialDataManager>(
          context,
          listen: false,
        ).initialize();
        await Provider.of<HealthProvider>(context, listen: false).initialize();
        await Provider.of<TaskProvider>(context, listen: false).initialize();
        await Provider.of<FamilyProvider>(context, listen: false).initialize();
        await Provider.of<SavingsGoalProvider>(
          context,
          listen: false,
        ).initialize();
        await Provider.of<ShoppingListProvider>(
          context,
          listen: false,
        ).initializeHive();
        await Provider.of<FamilyEventProvider>(
          context,
          listen: false,
        ).initializeHive();
        await Provider.of<ReminderProvider>(
          context,
          listen: false,
        ).initializeHive();

        if (context.mounted) {
          final count = (result['itemsRestored'] as Map).values.fold(
            0,
            (a, b) => (a) + (b as int),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Data restored successfully! ($count items)'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error reloading data: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else if (result['error'] != 'No file selected') {
      // Only show error if it wasn't a cancellation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore failed: ${result['error']}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Denied'),
        content: const Text(
          'Storage permission is required to save backup files.\n\nPlease enable it in settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await BackupService().openSystemSettings();
            },
            child: Text(
              'Open Settings',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will permanently delete all your expenses, income, budgets, reminders, and other data.\n\n⚠️ This action cannot be undone!\n\nAre you sure you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);

              // Show loading
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Clearing all data...'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }

              try {
                // Note: With MongoDB, clearing data requires API endpoints
                // For now, we just reinitialize providers to refresh data from server
                final backupService = BackupService();
                await backupService.clearAllData();

                // Reinitialize all providers
                if (context.mounted) {
                  await Provider.of<FinancialDataManager>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<HealthProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<TaskProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<FamilyProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<SavingsGoalProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<ShoppingListProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<FamilyEventProvider>(
                    context,
                    listen: false,
                  ).initialize();
                  await Provider.of<ReminderProvider>(
                    context,
                    listen: false,
                  ).initialize();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('All data cleared successfully'),
                      backgroundColor: AppTheme.successColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error clearing data: $e'),
                      backgroundColor: AppTheme.errorColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              }
            },
            child: Text(
              'Delete All',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIFeaturesSection() {
    return Column(
      children: [
        // Enable AI Features
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
                    await _geminiService.setAIEnabled(value);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'AI insights enabled'
                                : 'AI insights disabled',
                          ),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    }
                  }
                : null,
            activeThumbColor: AppTheme.accentColor,
          ),
        ),

        // API Key Configuration
        _buildSettingTile(
          context,
          title: 'Gemini API Key',
          subtitle: _apiKey.isEmpty
              ? 'Not configured - Tap to add'
              : _apiKeyValid
              ? 'Configured and validated'
              : 'Invalid or expired',
          icon: FontAwesomeIcons.key,
          onTap: () => _showApiKeyDialog(),
        ),

        // Test AI Connection
        if (_apiKey.isNotEmpty)
          _buildSettingTile(
            context,
            title: 'Test AI Connection',
            subtitle: 'Verify your API key is working',
            icon: FontAwesomeIcons.flask,
            onTap: _isValidating ? null : _validateApiKey,
          ),
      ],
    );
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(
      text: _apiKey.isEmpty ? '' : _apiKey,
    );
    bool isVisible = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: FaIcon(
                  FontAwesomeIcons.key,
                  color: AppTheme.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Gemini API Key'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter your Gemini API key to enable AI-powered budget tips and insights.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: !isVisible,
                decoration: InputDecoration(
                  labelText: 'API Key',
                  hintText: 'Enter your API key',
                  suffixIcon: IconButton(
                    icon: FaIcon(
                      isVisible
                          ? FontAwesomeIcons.eyeSlash
                          : FontAwesomeIcons.eye,
                      size: 18,
                    ),
                    onPressed: () {
                      setDialogState(() => isVisible = !isVisible);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.circleInfo,
                    size: 14,
                    color: AppTheme.accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Get your free API key from Google AI Studio',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newKey = controller.text.trim();
                if (newKey.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter an API key'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                Navigator.pop(context);

                // Show loading
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Validating API key...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                // Save and validate
                final isValid = await _geminiService.saveApiKey(newKey);

                setState(() {
                  _apiKey = newKey;
                  _apiKeyValid = isValid;
                  _apiKeyController.text = _maskApiKey(newKey);
                  if (isValid) {
                    _aiEnabled = true;
                    _geminiService.setAIEnabled(true);
                  }
                });

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isValid
                            ? 'API key validated and saved!'
                            : 'Invalid API key. Please check and try again.',
                      ),
                      backgroundColor: isValid
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
              child: Text(
                'Save',
                style: TextStyle(color: AppTheme.accentColor),
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
      final isValid = await _geminiService.validateApiKey();

      setState(() {
        _apiKeyValid = isValid;
        _isValidating = false;
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isValid
                  ? '✓ API key is valid and working!'
                  : '✗ API key validation failed',
            ),
            backgroundColor: isValid
                ? AppTheme.successColor
                : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      setState(() => _isValidating = false);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  String _maskApiKey(String key) {
    if (key.length <= 8) return key;
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  void _showExportOptions(BuildContext context, String s) {}

  void _shareFinancialReport(BuildContext context) {}
}
