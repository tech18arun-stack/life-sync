import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/expense.dart';
import '../models/income.dart';

import '../providers/financial_data_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/gemini_service.dart';
import '../services/startio_ads.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/premium_components.dart';
import '../widgets/circular_balance_dial.dart';

import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../widgets/upcoming_payment_card.dart';

import 'history_screen.dart';
import 'notification_history_screen.dart';
import 'savings_goals_screen.dart';
import 'ai_advisor_screen.dart';
import 'profile_screen.dart';
import 'reminder_screen.dart';
import 'financial_calendar_screen.dart';
import 'expenses_screen.dart';
import 'income_screen.dart';
import 'analytics_screen.dart';
import 'budget_screen.dart';
import 'tasks_screen.dart';
import 'reports_screen.dart';
import 'subscriptions_screen.dart';
import 'family_user_accounts_screen.dart';
import 'settings_screen.dart';
import '../widgets/horizontal_action_carousel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _aiTips;
  Map<String, dynamic>? _healthScore;
  int _adActionCount = 0;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeAI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReminderProvider>(context, listen: false).initialize();
      Provider.of<SavingsGoalProvider>(context, listen: false).initialize();
      _checkPremiumExpiryPopup();
    });
  }

  Future<void> _checkPremiumExpiryPopup() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.currentUser;
    if (user != null &&
        !user.isPremiumActive &&
        user.premiumExpiryDate != null) {
      final now = DateTime.now();
      final diff = now.difference(user.premiumExpiryDate!).inDays;
      if (diff >= 0 && diff <= 30) {
        final prefs = await SharedPreferences.getInstance();
        final todayStr = DateFormat('yyyy-MM-dd').format(now);
        String? slot;
        if (now.hour >= 6 && now.hour < 12) {
          slot = 'morning';
        } else if (now.hour >= 17 && now.hour < 22)
          slot = 'evening';

        if (slot != null) {
          final lastPopupKey = 'expired_popup_${slot}_$todayStr';
          if (prefs.getBool(lastPopupKey) != true) {
            if (mounted) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => PremiumExpiredPopup(
                  onRenew: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProfileScreen(),
                      ),
                    );
                  },
                  onDismiss: () => Navigator.pop(context),
                ),
              );
              await prefs.setBool(lastPopupKey, true);
            }
          }
        }
      }
    }
  }

  Future<void> _showAdAfterAction() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser?.isPremiumActive ?? false) return;
    _adActionCount++;
    if (_adActionCount % 3 == 0) {
      await StartIOAds.showVideoInterstitial(context);
    } else {
      await StartIOAds.showInterstitial(context);
    }
  }

  Future<void> _initializeAI() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final enabled = await geminiService.isAIEnabled();
    if (mounted) {
      if (enabled) _loadAIInsights();
    }
  }

  Future<void> _loadAIInsights() async {
    if (!mounted) return;
    try {
      final dm = Provider.of<FinancialDataManager>(context, listen: false);
      final gemini = Provider.of<GeminiService>(context, listen: false);
      final expenses = dm.getRecentExpenses(limit: 30);
      final budgets = dm.getActiveBudgets();
      final income = dm.getMonthlyIncome();
      final totalEx = dm.getTotalExpenses();

      final score = gemini.calculateFinancialHealth(
        monthlyIncome: income,
        monthlyExpenses: totalEx,
        totalSavings: 0,
        budgets: budgets,
      );

      String tips = '';
      if (expenses.isNotEmpty && budgets.isNotEmpty) {
        tips = await gemini.generateBudgetTips(
          expenses: expenses,
          budgets: budgets,
          monthlyIncome: income,
        );
      }

      if (mounted) {
        setState(() {
          _healthScore = score;
          _aiTips = tips.isNotEmpty ? tips : null;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;
    final fm = Provider.of<FinancialDataManager>(context);
    final rp = Provider.of<ReminderProvider>(context);
    final sp = Provider.of<SavingsGoalProvider>(context);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hPad = Responsive.getHorizontalPadding(context);
    final textP = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textS = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBody: true,
      bottomNavigationBar: (user?.isPremiumActive ?? false)
          ? null
          : const StartioBanner(),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadAIInsights();
              await rp.initialize();
              await sp.initialize();
            },
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    [
                          _buildModernHeader(user),
                          const SizedBox(height: 24),
                          if (user != null && !user.isUltra)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: _buildUpgradeBanner(user),
                            ),
                          const SizedBox(height: 24),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildBalanceSect(
                              user,
                              fm,
                              isDark,
                              textP,
                              textS,
                            ),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: PremiumSectionHeader(
                              title: 'Quick Access',
                              subtitle: 'Most frequent actions',
                              icon: Icons.auto_awesome_rounded,
                              onActionTap: _showAllActionsMenu,
                              actionLabel: 'All Actions',
                            ),
                          ),
                          _buildQuickCarousel(),
                          const SizedBox(height: 32),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildUpcomingSection(textP, rp),
                          ),
                          const SizedBox(height: 32),
                          if (_healthScore != null || _aiTips != null)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: hPad),
                              child: _buildAICard(isDark, textP, textS),
                            ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildGoalsSect(sp, textP),
                          ),
                          const SizedBox(height: 32),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: PremiumSectionHeader(
                              title: 'Recent Activity',
                              subtitle: 'Your latest money moves',
                              onActionTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const HistoryScreen(),
                                ),
                              ),
                              actionLabel: 'See All',
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            child: _buildTransactions(fm),
                          ),
                          const SizedBox(height: 100),
                        ]
                        .animate(interval: 50.ms)
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.1, curve: Curves.easeOutQuad),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddExpense,
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildModernHeader(dynamic user) {
    final hPad = Responsive.getHorizontalPadding(context);
    return Container(
      padding: EdgeInsets.fromLTRB(hPad, 24, hPad, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Start',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Hello, ${user?.name?.split(' ').first ?? 'User'}!',
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  if (user != null) _buildPlanBadge(user),
                ],
              ),
              Row(
                children: [
                  _buildIconBtn(
                    Icons.settings_rounded,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    isProminent: true,
                  ),
                  const SizedBox(width: 8),
                  _buildIconBtn(
                    Icons.notifications_none_rounded,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationHistoryScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      child: const CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(
                          Icons.person_rounded,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          PremiumTextField(
            controller: _searchController,
            hintText: 'Search for expenses, goals, tips...',
            prefixIcon: Icons.search_rounded,
            autofocus: false,
            onChanged: (val) {
              setState(() {
                // Rebuilds with filtered transactions
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCarousel() {
    final actions = [
      ActionCardItem(
        title: 'Expenses',
        icon: Icons.trending_down,
        colors: [const Color(0xFFFF6B6B), const Color(0xFFFF8E8E)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExpensesScreen()),
        ),
      ),
      ActionCardItem(
        title: 'Income',
        icon: Icons.trending_up,
        colors: [const Color(0xFF4CAF50), const Color(0xFF81C784)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const IncomeScreen()),
        ),
      ),
      ActionCardItem(
        title: 'Savings',
        icon: Icons.savings_rounded,
        colors: [const Color(0xFF6366F1), const Color(0xFF818CF8)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
        ),
      ),
      ActionCardItem(
        title: 'Budget',
        icon: Icons.account_balance_wallet,
        colors: [const Color(0xFFF59E0B), const Color(0xFFFBBF24)],
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const BudgetScreen()),
        ),
      ),
    ];
    return HorizontalActionCarousel(actions: actions);
  }

  void _showAllActionsMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Full Access Hub',
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: _buildQuickMenuGrid(isSheet: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickMenuGrid({bool isSheet = false}) {
    final items = [
      {
        'icon': Icons.trending_down,
        'label': 'Expenses',
        'screen': const ExpensesScreen(),
        'color': AppTheme.errorColor,
      },
      {
        'icon': Icons.trending_up,
        'label': 'Income',
        'screen': const IncomeScreen(),
        'color': AppTheme.successColor,
      },
      {
        'icon': Icons.settings,
        'label': 'Settings',
        'screen': const SettingsScreen(),
        'color': AppTheme.textSecondary,
      },
      {
        'icon': Icons.add_circle_outline,
        'label': 'Add Income',
        'onTap': _showAddIncome,
        'color': AppTheme.successColor,
      },
      {
        'icon': Icons.remove_circle_outline,
        'label': 'Add Expense',
        'onTap': _showAddExpense,
        'color': AppTheme.errorColor,
      },
      {
        'icon': Icons.pie_chart_outline,
        'label': 'Analytics',
        'screen': const AnalyticsScreen(),
        'color': AppTheme.accentBlue,
      },
      {
        'icon': Icons.account_balance_wallet,
        'label': 'Budget',
        'screen': const BudgetScreen(),
        'color': AppTheme.warningColor,
      },
      {
        'icon': Icons.savings,
        'label': 'Goal',
        'screen': const SavingsGoalsScreen(),
        'color': AppTheme.accentColor,
      },
      {
        'icon': Icons.task_alt,
        'label': 'Tasks',
        'screen': const TasksScreen(),
        'color': AppTheme.othersColor,
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'Reports',
        'screen': const ReportsScreen(),
        'color': AppTheme.primaryLight,
      },
      {
        'icon': Icons.history,
        'label': 'History',
        'screen': const HistoryScreen(),
        'color': Colors.grey,
      },
      {
        'icon': Icons.subscriptions,
        'label': 'Subs',
        'screen': const SubscriptionsScreen(),
        'color': AppTheme.entertainmentColor,
      },
      {
        'icon': Icons.people_outline,
        'label': 'Family',
        'screen': const FamilyUserAccountsScreen(),
        'color': AppTheme.groceriesColor,
      },
      {
        'icon': Icons.calendar_month_outlined,
        'label': 'Calendar',
        'screen': const FinancialCalendarScreen(),
        'color': AppTheme.travelColor,
      },
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        return InkWell(
              onTap: () {
                if (isSheet) Navigator.pop(context);
                if (item.containsKey('onTap')) {
                  (item['onTap'] as VoidCallback)();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => item['screen'] as Widget),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: (item['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: item['color'] as Color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item['label'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
            .animate(delay: (i * 30).ms)
            .fade(duration: 400.ms)
            .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildPlanBadge(dynamic user) {
    Color bColor = user.isUltra
        ? const Color(0xFFF59E0B)
        : (user.isPremiumActive ? AppTheme.primaryColor : Colors.grey);
    String bText = user.isUltra
        ? 'ULTRA'
        : (user.isPremiumActive ? 'PREMIUM' : 'BASIC');
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bColor.withOpacity(0.3)),
      ),
      child: Text(
        bText,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: bColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildUpgradeBanner(dynamic user) {
    final nextStr = user.isPremiumActive ? 'ULTRA' : 'PREMIUM';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Colors.white, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unlock $nextStr Features',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Upgrade now to remove ads and get more tools.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Upgrade',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceSect(
    dynamic user,
    FinancialDataManager fm,
    bool isDark,
    Color textP,
    Color textS,
  ) {
    if (user != null && user.isUltra) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [AppTheme.cardShadow],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CircularBalanceDial(
              balance: fm.getAvailableBalance(),
              income: fm.getMonthlyIncome(),
              expenses: fm.getMonthlyExpenses(),
              userName: user.name ?? 'User',
              onProfileTap: () {},
              size: 130,
              label: 'Balance',
            ),
            CircularBalanceDial(
              balance: fm.getMonthlyIncome(),
              income: fm.getMonthlyIncome(),
              expenses: 0,
              userName: user.name ?? 'User',
              onProfileTap: () {},
              size: 130,
              label: 'Monthly',
            ),
          ],
        ),
      );
    } else if (user != null && user.isPremiumActive) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [AppTheme.cardShadow],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Balance',
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${fm.getAvailableBalance().toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildStat(
                    'Income',
                    fm.getMonthlyIncome(),
                    Icons.arrow_downward,
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStat(
                    'Expenses',
                    fm.getMonthlyExpenses(),
                    Icons.arrow_upward,
                    Colors.redAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  colors: [Color(0xFF2C2C3E), Color(0xFF1E1E2C)],
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF0F4FF)],
                ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.5)
                  : AppTheme.accentBlue.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Balance',
              style: GoogleFonts.inter(color: textS, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${fm.getAvailableBalance().toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: textP,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unlock detailed charts in Premium.',
              style: GoogleFonts.inter(color: textS, fontSize: 11),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStat(String label, double amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 10),
            ),
            Text(
              '₹${amount.toStringAsFixed(0)}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpcomingSection(Color textP, ReminderProvider rp) {
    final pending = rp.getPendingReminders();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Upcoming Payments',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textP,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReminderScreen()),
              ),
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: pending.isNotEmpty
                ? pending
                      .map(
                        (r) => UpcomingPaymentCard(
                          title: r.title,
                          amount: r.amount ?? 0,
                          timeLeft:
                              '${r.dueDate.difference(DateTime.now()).inDays} days left',
                          icon: Icons.receipt_long,
                          color: AppTheme.primaryColor,
                        ),
                      )
                      .toList()
                : [_buildAddReminder()],
          ),
        ),
      ],
    );
  }

  Widget _buildAddReminder() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReminderScreen()),
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Add Bill',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAICard(bool isDark, Color textP, Color textS) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.surfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppTheme.softShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Health Scorer',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (_healthScore != null) ...[
            Text(
              'Score: ${_healthScore!['score']}/100',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _healthScore!['status'] ?? '',
              style: GoogleFonts.inter(fontSize: 12, color: textS),
            ),
          ],
          if (_aiTips != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _aiTips!,
              style: GoogleFonts.inter(fontSize: 14, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AIAdvisorScreen()),
              ),
              child: const Text('Ask AI Advisor'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsSect(SavingsGoalProvider sp, Color textP) {
    final goals = sp.goals;
    if (goals.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Goals',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textP,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...goals.take(2).map((goal) {
          final prog = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [AppTheme.softShadow],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      goal.title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${(prog * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: prog,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTransactions(FinancialDataManager fm) {
    var list = fm.getRecentTransactions(limit: 10);
    final query = _searchController.text.toLowerCase();

    if (query.isNotEmpty) {
      list = list.where((tx) {
        final isExpense = tx is Expense;
        final category = (isExpense ? tx.category : (tx as Income).source)
            .toLowerCase();
        final description =
            (isExpense ? tx.description : (tx as Income).description)
                .toLowerCase();
        return category.contains(query) || description.contains(query);
      }).toList();
    }

    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'No matching transactions',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return Column(
      children: list.map((tx) {
        final isExpense = tx is Expense;
        final category = isExpense ? tx.category : (tx as Income).source;
        final color = AppTheme.getCategoryColor(category);
        final icon = AppTheme.getCategoryIcon(category);
        final amount = isExpense
            ? '-₹${tx.amount.toStringAsFixed(0)}'
            : '+₹${(tx as Income).amount.toStringAsFixed(0)}';
        final amountColor = isExpense
            ? AppTheme.errorColor
            : AppTheme.successColor;
        final description = isExpense
            ? tx.description
            : (tx as Income).description;
        final displayTitle = description.isNotEmpty ? description : category;
        final date = isExpense ? tx.date : (tx as Income).date;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      DateFormat('MMM d').format(date),
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Text(
                amount,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: amountColor,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showAddIncome() {
    showDialog(
      context: context,
      builder: (context) => const AddIncomeDialog(),
    ).then((_) => _showAdAfterAction());
  }

  void _showAddExpense() {
    showDialog(
      context: context,
      builder: (context) => const AddExpenseDialog(),
    ).then((_) => _showAdAfterAction());
  }

  Widget _buildIconBtn(
    IconData icon,
    VoidCallback onTap, {
    bool isProminent = false,
  }) {
    final isD = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isProminent
              ? AppTheme.primaryColor.withValues(alpha: 0.1)
              : (isD
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.05)),
          shape: BoxShape.circle,
          border: isProminent
              ? Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2))
              : null,
        ),
        child: Icon(
          icon,
          size: 22,
          color: isProminent
              ? AppTheme.primaryColor
              : (isD ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }
}
