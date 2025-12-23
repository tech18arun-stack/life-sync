import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../providers/auth_provider.dart';
import 'income_screen.dart';
import 'budget_screen.dart';
import 'settings_screen.dart';
import 'reports_screen.dart';
import 'reminder_screen.dart';
import 'savings_goals_screen.dart';
import 'shopping_list_screen.dart';
import 'financial_calendar_screen.dart';
import 'family_user_accounts_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  void _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // User Profile Header
              if (user != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              user.email,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text('Menu', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 32),

              // Financial Section
              Text(
                'FINANCIAL',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Income',
                subtitle: 'Manage your earnings',
                icon: FontAwesomeIcons.moneyBillTrendUp,
                color: AppTheme.successColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const IncomeScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Budgets',
                subtitle: 'Set limits and track spending',
                icon: FontAwesomeIcons.piggyBank,
                color: AppTheme.accentColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BudgetScreen()),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Reminders',
                subtitle: 'Bill payments & alerts',
                icon: FontAwesomeIcons.bell,
                color: AppTheme.warningColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReminderScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Reports',
                subtitle: 'Visualize your finances',
                icon: FontAwesomeIcons.chartPie,
                color: AppTheme.infoColor,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Savings Goals',
                subtitle: 'Track your saving targets',
                icon: FontAwesomeIcons.bullseye,
                color: Colors.green,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SavingsGoalsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Financial Calendar',
                subtitle: 'View income & expenses by date',
                icon: FontAwesomeIcons.calendarDays,
                color: Colors.purple,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinancialCalendarScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Family Management Section
              Text(
                'FAMILY',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
 
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Family User Accounts',
                subtitle: 'Create login accounts for family',
                icon: FontAwesomeIcons.usersGear,
                color: Colors.teal,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FamilyUserAccountsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Shopping List',
                subtitle: 'Shared family shopping',
                icon: FontAwesomeIcons.cartShopping,
                color: Colors.orange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingListScreen(),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Section
              Text(
                'APP',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuCard(
                context,
                title: 'Settings',
                subtitle: 'Theme, backup, and more',
                icon: FontAwesomeIcons.gear,
                color: AppTheme.textSecondary,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMenuCard(
                context,
                title: 'Logout',
                subtitle: 'Sign out of your account',
                icon: FontAwesomeIcons.rightFromBracket,
                color: AppTheme.errorColor,
                onTap: () => _handleLogout(context),
              ),
              const SizedBox(height: 80), // Extra space at bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
