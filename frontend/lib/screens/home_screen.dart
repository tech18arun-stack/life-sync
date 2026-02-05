import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../providers/auth_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAI();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReminderProvider>(context, listen: false).initialize();
      Provider.of<SavingsGoalProvider>(context, listen: false).initialize();
    });
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

    // Dynamic Theme Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    const accentBlue = Color(0xFF2E65F3);
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadAIInsights();
            await reminderProvider.initialize();
            await savingsProvider.initialize();
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: cardColor,
                          child: Text(
                            (user != null && user.name.isNotEmpty)
                                ? user.name.substring(0, 1).toUpperCase()
                                : 'U',
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good morning!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                            Text(
                              user?.name ?? 'User',
                              style: GoogleFonts.inter(
                                fontSize: 18,
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
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HistoryScreen(),
                              ),
                            );
                          },
                          icon: Icon(Icons.search, color: textPrimary),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const NotificationHistoryScreen(),
                                ),
                              );
                            },
                            icon: Icon(
                              Icons.notifications_none,
                              color: textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // 2. Total Balance
                Text(
                  'Total Balance',
                  style: GoogleFonts.inter(fontSize: 14, color: textSecondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '₹${financialManager.getMonthlyAvailableBalance().toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3A2F),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '+₹${financialManager.getMonthlyIncome().toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const AddIncomeDialog(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cardColor,
                          foregroundColor: textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('+ Deposit'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => showDialog(
                          context: context,
                          builder: (_) => const AddExpenseDialog(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(
                          Icons.swap_horiz,
                          size: 20,
                          color: Colors.white,
                        ),
                        label: const Text('Transfer'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: () {
                        _showAllServicesSheet(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.grid_view,
                          color: textPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // 3.5 AI Insight (if available)
                if (_healthScore != null || _aiTips != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentBlue.withValues(alpha: 0.2),
                          isDark ? Colors.black26 : Colors.white10,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentBlue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome,
                              color: accentBlue,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'AI Insight',
                              style: GoogleFonts.inter(
                                color: accentBlue,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_healthScore != null)
                          Text(
                            'Your financial health score is ${_healthScore!['score']}/100.',
                            style: GoogleFonts.inter(
                              color: textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        if (_aiTips != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _aiTips!,
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                // 4. My Goals (Horizontal List)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'My Goals',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddBudgetDialog(),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add, color: textPrimary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Add',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 180,
                  child: savingsProvider.activeGoals.isEmpty
                      ? _buildEmptyStateCard(
                          context,
                          'No active goals',
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SavingsGoalsScreen(),
                            ),
                          ),
                        )
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: savingsProvider.activeGoals.length,
                          itemBuilder: (context, index) {
                            final goal = savingsProvider.activeGoals[index];
                            return Container(
                              width: 280,
                              margin: const EdgeInsets.only(right: 16),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: index % 2 == 0
                                      ? [
                                          const Color(0xFF2E65F3),
                                          const Color(0xFF152A72),
                                        ]
                                      : [
                                          const Color(0xFF7A2EF3),
                                          const Color(0xFF2A0F5B),
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        goal.name,
                                        style: GoogleFonts.inter(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.white54,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saved',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '₹${goal.currentAmount.toStringAsFixed(2)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Target: ₹${goal.targetAmount.toStringAsFixed(0)}',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Progess',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white54,
                                        ),
                                      ),
                                      Text(
                                        '${((goal.currentAmount / goal.targetAmount) * 100).toStringAsFixed(1)}%',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
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

                const SizedBox(height: 30),

                // 5. Upcoming Payment (Reminder)
                if (reminderProvider.getPendingReminders().isNotEmpty) ...[
                  Text(
                    'Upcoming Payment',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2C2B3E)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(Icons.receipt_long, color: textPrimary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reminderProvider
                                    .getPendingReminders()
                                    .first
                                    .title,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Due ${DateFormat('MMM d').format(reminderProvider.getPendingReminders().first.dueDate)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            _showPayReminderDialog(
                              context,
                              reminderProvider.getPendingReminders().first,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          child: const Text('Pay Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],

                // 6. Transactions
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Transactions',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      ),
                      child: Text(
                        'See More',
                        style: TextStyle(color: textSecondary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildRecentTransactionsList(financialManager, context),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
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
      onTap: onTap,
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
