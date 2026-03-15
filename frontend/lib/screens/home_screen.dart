import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import '../providers/financial_data_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/gemini_service.dart';
import '../services/startio_ads.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/premium_components.dart';
import '../services/config_service.dart';

import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/add_budget_dialog.dart';

import 'income_screen.dart';
import 'budget_screen.dart';
import 'reminder_screen.dart';
import 'financial_calendar_screen.dart';
import 'analytics_screen.dart';
import 'family_user_accounts_screen.dart';
import 'history_screen.dart';
import 'notification_history_screen.dart';
import 'expenses_screen.dart';
import 'health_screen.dart';
import 'tasks_screen.dart';
import 'settings_screen.dart';
import 'savings_goals_screen.dart';
import 'reports_screen.dart';
import 'ai_advisor_screen.dart';
import 'subscriptions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _aiEnabled = false;
  // ignore: unused_field
  bool _isLoadingTips = false;
  String? _aiTips;
  Map<String, dynamic>? _healthScore;
  int _adActionCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeAI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReminderProvider>(context, listen: false).initialize();
      Provider.of<SavingsGoalProvider>(context, listen: false).initialize();
    });
  }

  Future<void> _showAdAfterAction() async {
    _adActionCount++;
    if (_adActionCount % 3 == 0) {
      await StartIOAds.showVideoInterstitial();
    } else {
      await StartIOAds.showInterstitial();
    }
  }

  Future<void> _initializeAI() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final enabled = await geminiService.isAIEnabled();
    if (mounted) {
      setState(() {
        _aiEnabled = enabled;
      });
      if (_aiEnabled) {
        _loadAIInsights();
      }
    }
  }

  Future<void> _loadAIInsights() async {
    if (!mounted) return;
    setState(() => _isLoadingTips = true);

    try {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );
      final expenses = financialManager.getRecentExpenses(limit: 30);
      final budgets = financialManager.getActiveBudgets();
      final income = financialManager.getMonthlyIncome();
      final totalExpenses = financialManager.getTotalExpenses();

      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final score = geminiService.calculateFinancialHealth(
        monthlyIncome: income,
        monthlyExpenses: totalExpenses,
        totalSavings: 0,
        budgets: budgets,
      );

      String tips = '';
      if (expenses.isNotEmpty && budgets.isNotEmpty) {
        tips = await geminiService.generateBudgetTips(
          expenses: expenses,
          budgets: budgets,
          monthlyIncome: income,
        );
      }

      if (mounted) {
        setState(() {
          _healthScore = score;
          _aiTips = tips.isNotEmpty ? tips : null;
          _isLoadingTips = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingTips = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final financialManager = Provider.of<FinancialDataManager>(context);
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final savingsProvider = Provider.of<SavingsGoalProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final horizontalPadding = Responsive.getHorizontalPadding(context);

    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const StartioBanner(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadAIInsights();
            await reminderProvider.initialize();
            await savingsProvider.initialize();
          },
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: isDesktop ? 24 : (isTablet ? 20 : 16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (StartIOAds.isAdBlockerActive) _buildAdBlockWarning(context),
                SizedBox(height: isDesktop ? 24 : 16),
                // 1. Premium Header with Avatar
                _buildPremiumHeader(user, textPrimary, textSecondary, cardColor, context),

                SizedBox(height: isDesktop ? 32 : 24),

                // 2. Premium Balance Card (Gradient with Glassmorphism)
                _buildPremiumBalanceCard(financialManager, context, isDark),

                SizedBox(height: isDesktop ? 24 : 20),

                // 3. Premium Action Buttons (Pill-shaped with gradients)
                _buildPremiumActionButtons(context, cardColor, textPrimary),

                SizedBox(height: isDesktop ? 24 : 20),

                // 4. AI Insight Card (Glassmorphic)
                if (_healthScore != null || _aiTips != null)
                  _buildPremiumAICard(context, isDark, textPrimary, textSecondary),

                SizedBox(height: isDesktop ? 24 : 20),

                // 5. My Goals Section (Horizontal Scroll with Premium Cards)
                _buildPremiumGoalsSection(savingsProvider, context, textPrimary),

                SizedBox(height: isDesktop ? 32 : 24),

                // 6. Upcoming Payment (Reminder with Premium Styling)
                if (reminderProvider.getPendingReminders().isNotEmpty) ...[
                  _buildPremiumReminderCard(reminderProvider, context, isDark, textPrimary, textSecondary),
                  SizedBox(height: isDesktop ? 32 : 24),
                ],

                // 7. Transactions Section
                Text(
                  'Transactions',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.getFontSize(context, FontSizeType.title),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRecentTransactionsList(financialManager, context),

                SizedBox(height: isDesktop ? 48 : 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Ad-Blocker Warning Widget
  Widget _buildAdBlockWarning(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.warningColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: AppTheme.warningColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad-Blocker Detected',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppTheme.warningColor,
                  ),
                ),
                Text(
                  'Please whitelist LifeSync to keep the app free and supported.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              // Re-check ad-blocker status
              await StartIOAds.initialize(ConfigService().startioAppId);
              if (mounted) setState(() {});
              if (!StartIOAds.isAdBlockerActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Thank you! Ad-blocker disabled.')),
                );
              }
            },
            child: Text(
              'RETRY',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Premium Header Widget
  Widget _buildPremiumHeader(
    dynamic user,
    Color textPrimary,
    Color textSecondary,
    Color cardColor,
    BuildContext context,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final avatarRadius = Responsive.getAvatarRadius(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // Premium Avatar with gradient border
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: isDesktop ? 15 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarRadius,
                backgroundColor: cardColor,
                child: Text(
                  (user != null && user.name.isNotEmpty)
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'U',
                  style: TextStyle(
                    color: textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: isDesktop ? 24 : 20,
                  ),
                ),
              ),
            ),
            SizedBox(width: isDesktop ? 16 : 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_getGreeting()}!',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.getFontSize(context, FontSizeType.small),
                    color: textSecondary,
                  ),
                ),
                Text(
                  user?.name ?? 'User',
                  style: GoogleFonts.inter(
                    fontSize: isDesktop
                        ? Responsive.getFontSize(context, FontSizeType.title)
                        : Responsive.getFontSize(context, FontSizeType.subtitle),
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            // Search Button
            _buildIconButton(Icons.search, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            }, context),
            SizedBox(width: isDesktop ? 12 : 8),
            // Notification Button with premium styling
            _buildIconButton(Icons.notifications_none, () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationHistoryScreen()),
              );
            }, context),
          ],
        ),
      ],
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final iconSize = isDesktop ? 24.0 : 20.0;
    final containerSize = isDesktop ? 48.0 : 44.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Theme.of(context).textTheme.bodyLarge?.color,
          size: iconSize,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.accentBlue;
    if (score >= 40) return Colors.orange;
    return AppTheme.errorColor;
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }

  // Premium Balance Card with Deep Purple Gradient and Glassmorphism details
  Widget _buildPremiumBalanceCard(
    FinancialDataManager financialManager,
    BuildContext context,
    bool isDark,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cardRadius = Responsive.getCardRadius(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 28 : 24)),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Abstract Shape
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Balance',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.getFontSize(context, FontSizeType.small),
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${financialManager.getAvailableBalance().toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 42 : 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildBalanceIndicator(
                    context,
                    'Income',
                    '₹${financialManager.getMonthlyIncome().toStringAsFixed(0)}',
                    Icons.arrow_downward,
                    Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 12),
                  _buildBalanceIndicator(
                    context,
                    'Expenses',
                    '₹${financialManager.getTotalExpenses().toStringAsFixed(0)}',
                    Icons.arrow_upward,
                    Colors.white.withOpacity(0.2),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceIndicator(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Premium Action Buttons (Pill-shaped with gradients and glassmorphism)
  Widget _buildPremiumActionButtons(BuildContext context, Color cardColor, Color textPrimary) {
    final isDesktop = Responsive.isDesktop(context);
    final buttonHeight = isDesktop ? 64.0 : 56.0;
    final buttonRadius = 20.0;

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'Deposit',
            icon: Icons.add_circle_outline,
            gradient: AppTheme.successGradient,
            onTap: () async {
              await showDialog(
                context: context,
                builder: (_) => const AddIncomeDialog(),
              );
              await _showAdAfterAction();
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            context: context,
            label: 'Transfer',
            icon: Icons.swap_horizontal_circle_outlined,
            gradient: AppTheme.blueGradient,
            onTap: () async {
              await showDialog(
                context: context,
                builder: (_) => const AddExpenseDialog(),
              );
              await _showAdAfterAction();
            },
          ),
        ),
        SizedBox(width: 12),
        _buildServiceGridButton(context, buttonHeight, buttonRadius, cardColor, textPrimary),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceGridButton(
    BuildContext context,
    double height,
    double radius,
    Color cardColor,
    Color textPrimary,
  ) {
    return GestureDetector(
      onTap: () => _showAllServicesSheet(context),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          Icons.grid_view_rounded,
          color: AppTheme.primaryColor,
          size: 24,
        ),
      ),
    );
  }

  // Premium AI Insight Card (Glassmorphic)
  Widget _buildPremiumAICard(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cardRadius = Responsive.getCardRadius(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(isDesktop ? 24 : (isTablet ? 20 : 16)),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.accentBlue.withValues(alpha: 0.15),
                isDark ? Colors.black.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.5),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: AppTheme.accentBlue.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isDesktop ? 10 : 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentBlue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.accentBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Insight',
                    style: GoogleFonts.inter(
                      color: AppTheme.accentBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isDesktop ? 16 : 12),
              if (_healthScore != null)
                Row(
                  children: [
                    PremiumGauge(
                      value: (_healthScore!['score'] as int) / 100,
                      size: isDesktop ? 100 : 80,
                      progressColor: _getScoreColor(_healthScore!['score']),
                      showPercentage: true,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _healthScore!['rating'] ?? 'Financial Score',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                            ),
                          ),
                          Text(
                            _healthScore!['message'] ?? 'Keep optimizing to improve.',
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              if (_aiTips != null) ...[
                SizedBox(height: isDesktop ? 12 : 8),
                Text(
                  _aiTips!,
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: Responsive.getFontSize(context, FontSizeType.body),
                    height: 1.5,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AIAdvisorScreen()),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 16),
                  label: Text(
                    'Chat with AI Assistant',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.2),
                    foregroundColor: AppTheme.accentBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Premium Goals Section
  Widget _buildPremiumGoalsSection(
    SavingsGoalProvider savingsProvider,
    BuildContext context,
    Color textPrimary,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final cardRadius = Responsive.getCardRadius(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Goals',
              style: GoogleFonts.inter(
                fontSize: Responsive.getFontSize(context, FontSizeType.title),
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddBudgetDialog()),
                );
                await _showAdAfterAction();
              },
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.getFontSize(context, FontSizeType.body),
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 20 : 16),
        SizedBox(
          height: isDesktop ? 200 : 180,
          child: savingsProvider.activeGoals.isEmpty
              ? _buildEmptyStateCard(
                  context,
                  'No active goals',
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: savingsProvider.activeGoals.length,
                  itemBuilder: (context, index) {
                    final goal = savingsProvider.activeGoals[index];
                    return Container(
                      width: isDesktop ? 320 : 280,
                      margin: const EdgeInsets.only(right: 16),
                      padding: EdgeInsets.all(isDesktop ? 28 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: index % 2 == 0
                              ? AppTheme.blueGradient.colors
                              : AppTheme.purpleGradient.colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(cardRadius),
                        boxShadow: [
                          BoxShadow(
                            color: (index % 2 == 0 ? AppTheme.accentBlue : AppTheme.primaryColor)
                                .withValues(alpha: 0.3),
                            blurRadius: isDesktop ? 20 : 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  goal.name,
                                  style: GoogleFonts.inter(
                                    fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.star, color: Colors.white54),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Saved',
                                style: GoogleFonts.inter(
                                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${goal.currentAmount.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(
                                  fontSize: isDesktop ? 28 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Target: ₹${goal.targetAmount.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: GoogleFonts.inter(
                                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                                  color: Colors.white54,
                                ),
                              ),
                              Text(
                                '${((goal.currentAmount / goal.targetAmount) * 100).toStringAsFixed(1)}%',
                                style: GoogleFonts.inter(
                                  fontSize: Responsive.getFontSize(context, FontSizeType.small),
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Premium Reminder Card
  Widget _buildPremiumReminderCard(
    ReminderProvider reminderProvider,
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final cardRadius = Responsive.getCardRadius(context);
    final cardColor = Theme.of(context).cardColor;
    final pendingReminders = reminderProvider.getPendingReminders();

    if (pendingReminders.isEmpty) return const SizedBox.shrink();
    final reminder = pendingReminders.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSectionHeader(
          title: 'Upcoming Payment',
          icon: Icons.receipt_long,
        ),
        SizedBox(height: isDesktop ? 16 : 12),
        Container(
          padding: EdgeInsets.all(isDesktop ? 20 : 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(cardRadius),
            border: Border.all(
              color: AppTheme.warningColor.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                blurRadius: isDesktop ? 15 : 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 14 : 12),
                decoration: BoxDecoration(
                  gradient: AppTheme.sunsetGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 20),
              ),
              SizedBox(width: isDesktop ? 16 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title,
                      style: GoogleFonts.inter(
                        fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${DateFormat('MMM d').format(reminder.dueDate)}',
                      style: GoogleFonts.inter(
                        fontSize: Responsive.getFontSize(context, FontSizeType.small),
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: Responsive.getButtonHeight(context) - 10,
                decoration: BoxDecoration(
                  gradient: AppTheme.blueGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton(
                  onPressed: () => _showPayReminderDialog(context, reminder),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 20 : 16,
                      vertical: isDesktop ? 12 : 10,
                    ),
                  ),
                  child: Text(
                    'Pay',
                    style: GoogleFonts.inter(
                      fontSize: Responsive.getFontSize(context, FontSizeType.small),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAllServicesSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'All Services',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 4,
                    mainAxisSpacing: 24,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.75, // Fixed pixel issue
                    children: [
                      _buildServiceIcon(
                        context,
                        'Expenses',
                        FontAwesomeIcons.receipt,
                        Colors.red,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ExpensesScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Income',
                        FontAwesomeIcons.moneyBillTrendUp,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const IncomeScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Budget',
                        FontAwesomeIcons.piggyBank,
                        Colors.blue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BudgetScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Savings',
                        FontAwesomeIcons.bullseye,
                        const Color(0xFFF39C12),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavingsGoalsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Reports',
                        FontAwesomeIcons.chartLine,
                        const Color(0xFF9B59B6),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Calendar',
                        FontAwesomeIcons.calendarDays,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FinancialCalendarScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Health',
                        FontAwesomeIcons.heartPulse,
                        const Color(0xFFE74C3C),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HealthScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Tasks',
                        FontAwesomeIcons.listCheck,
                        const Color(0xFF34495E),
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TasksScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Reminders',
                        FontAwesomeIcons.bell,
                        Colors.teal,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReminderScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Family',
                        FontAwesomeIcons.users,
                        Colors.indigo,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FamilyUserAccountsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Analytics',
                        FontAwesomeIcons.chartPie,
                        Colors.deepOrange,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AnalyticsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'History',
                        FontAwesomeIcons.clockRotateLeft,
                        Colors.brown,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Settings',
                        FontAwesomeIcons.gear,
                        Colors.grey,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'Subs',
                        FontAwesomeIcons.repeat,
                        Colors.pink,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SubscriptionsScreen(),
                          ),
                        ),
                      ),
                      _buildServiceIcon(
                        context,
                        'AI Chat',
                        FontAwesomeIcons.robot,
                        AppTheme.accentBlue,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AIAdvisorScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPayReminderDialog(BuildContext context, dynamic reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          'Mark as Paid?',
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        content: Text(
          'Do you want to mark "${reminder.title}" as paid?',
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<ReminderProvider>(
                context,
                listen: false,
              ).markAsPaid(reminder.id!);
              Navigator.pop(context);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateCard(
    BuildContext context,
    String title,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_circle,
              size: 40,
              color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceIcon(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: () async {
        onTap();
        // Show ad after visiting certain screens
        await _showAdAfterAction();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: FaIcon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactionsList(
    FinancialDataManager manager,
    BuildContext context,
  ) {
    final transactions = manager.getRecentExpenses(limit: 5);
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: FaIcon(
                FontAwesomeIcons.receipt,
                size: 24,
                color: textSecondary.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No recent transactions',
              style: GoogleFonts.inter(
                color: textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: transactions.map((txn) {
        final color = AppTheme.getCategoryColor(txn.category);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  AppTheme.getCategoryIcon(txn.category),
                  size: 18,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      txn.description.isNotEmpty
                          ? txn.description
                          : txn.category,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(txn.date),
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '-₹${NumberFormat('#,##,##0').format(txn.amount)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
