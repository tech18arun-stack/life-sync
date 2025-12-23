import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/financial_data_manager.dart';
import '../providers/health_provider.dart';
import '../providers/task_provider.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/reminder_provider.dart';
import '../providers/shopping_list_provider.dart';
import '../providers/family_event_provider.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';
import '../widgets/stat_card.dart';
import '../widgets/recent_expense_card.dart';
import '../widgets/task_item.dart';
import '../widgets/financial_health_card.dart';
import '../widgets/budget_gauge_chart.dart';
import '../widgets/ai_tips_card.dart';
import '../widgets/financial_health_score.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'income_screen.dart';
import 'budget_screen.dart';
import 'reminder_screen.dart';
import 'savings_goals_screen.dart';
import 'shopping_list_screen.dart';
import 'reports_screen.dart';
import 'financial_calendar_screen.dart';
import 'analytics_screen.dart';
import '../widgets/spending_trends_chart.dart';
import '../widgets/add_task_dialog.dart';
import '../providers/family_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _geminiService = GeminiService();
  bool _aiEnabled = false;
  bool _isLoadingTips = false;
  String? _aiTips;
  Map<String, dynamic>? _healthScore;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await _geminiService.initialize();
    final enabled = await _geminiService.isAIEnabled();
    setState(() {
      _aiEnabled = enabled;
    });
    if (_aiEnabled) {
      _loadAIInsights();
    }
  }

  Future<void> _loadAIInsights() async {
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

      // Calculate health score
      final score = _geminiService.calculateFinancialHealth(
        monthlyIncome: income,
        monthlyExpenses: totalExpenses,
        totalSavings: 0, // This could be enhanced with savings data
        budgets: budgets,
      );

      // Generate AI tips
      String tips = '';
      if (expenses.isNotEmpty && budgets.isNotEmpty) {
        tips = await _geminiService.generateBudgetTips(
          expenses: expenses,
          budgets: budgets,
          monthlyIncome: income,
        );
      }

      setState(() {
        _healthScore = score;
        _aiTips = tips.isNotEmpty ? tips : null;
        _isLoadingTips = false;
      });
    } catch (e) {
      setState(() => _isLoadingTips = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final financialManager = Provider.of<FinancialDataManager>(context);
    final healthProvider = Provider.of<HealthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);
    final savingsProvider = Provider.of<SavingsGoalProvider>(context);
    final reminderProvider = Provider.of<ReminderProvider>(context);
    final shoppingProvider = Provider.of<ShoppingListProvider>(context);
    final eventProvider = Provider.of<FamilyEventProvider>(context);

    final totalExpenses = financialManager.getTotalExpenses();
    final totalIncome = financialManager.getMonthlyIncome();
    final recentExpenses = financialManager.getRecentExpenses(limit: 5);
    final upcomingVisits = healthProvider.getUpcomingVisits();
    final todayTasks = taskProvider.getTodayTasks();
    final overdueTasks = taskProvider.getOverdueTasks();
    final overBudgets = financialManager.getOverBudgets();
    final upcomingReminders = reminderProvider.getDueSoonReminders();
    final shoppingItems = shoppingProvider.activeItems;
    final upcomingEvents = eventProvider.getUpcomingEvents();
    final activeBudgets = financialManager.getActiveBudgets();
    final dailySpending = financialManager.getDailySpending();

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              snap: true,
              pinned: false,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                title: Text(
                  'LifeSync',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: Text(
                      DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Financial Health Card (Moved to Top)
                  const FinancialHealthCard(),

                  // AI-Powered Budget Gauge
                  if (_aiEnabled && activeBudgets.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: BudgetGaugeChart(
                        budgets: activeBudgets,
                        totalSpent: totalExpenses,
                        totalBudget: activeBudgets.fold<double>(
                          0,
                          (sum, b) => sum + b.allocatedAmount,
                        ),
                      ),
                    ),

                  // Financial Health Score
                  if (_aiEnabled && _healthScore != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: FinancialHealthScore(
                        score: _healthScore!['score'] as int,
                        rating: _healthScore!['rating'] as String,
                        message: _healthScore!['message'] as String,
                      ),
                    ),

                  // AI Tips Card
                  if (_aiEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: AITipsCard(
                        tip: _aiTips,
                        isLoading: _isLoadingTips,
                        onRefresh: _loadAIInsights,
                        title: '💡 AI Budget Tips',
                      ),
                    ),

                  // Spending Trends Chart (New Feature)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: SpendingTrendsChart(dailySpending: dailySpending),
                  ),

                  // Analytics Dashboard Card
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AnalyticsScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.analytics_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Analytics Dashboard',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'View trends & predictions',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Quick Stats Overview
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Available',
                                value:
                                    '₹${financialManager.getMonthlyAvailableBalance().toStringAsFixed(0)}',
                                subtitle: 'Balance',
                                icon: FontAwesomeIcons.wallet,
                                gradient: AppTheme.accentGradient,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Income',
                                value: '₹${totalIncome.toStringAsFixed(0)}',
                                subtitle: 'This month',
                                icon: FontAwesomeIcons.arrowTrendUp,
                                gradient: LinearGradient(
                                  colors: [
                                    AppTheme.successColor,
                                    AppTheme.successColor.withValues(
                                      alpha: 0.7,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Expenses',
                                value: '₹${totalExpenses.toStringAsFixed(0)}',
                                subtitle: 'This month',
                                icon: FontAwesomeIcons.arrowTrendDown,
                                gradient: AppTheme.primaryGradient,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Tasks Today',
                                value: '${todayTasks.length}',
                                subtitle: 'Due today',
                                icon: FontAwesomeIcons.checkDouble,
                                gradient: AppTheme.accentGradient,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: StatCard(
                                title: 'Shopping',
                                value: '${shoppingItems.length}',
                                subtitle: 'Items to buy',
                                icon: FontAwesomeIcons.cartShopping,
                                gradient: AppTheme.accentGradient,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Quick Actions
                        _buildSectionHeader(
                          context,
                          'Quick Actions',
                          FontAwesomeIcons.bolt,
                        ),
                        const SizedBox(height: 12),
                        _buildQuickActions(context),

                        const SizedBox(height: 24),

                        // Family Members (New Feature)
                        _buildFamilyMembers(context),

                        const SizedBox(height: 24),

                        // Budget Alerts
                        if (overBudgets.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Budget Alerts',
                            FontAwesomeIcons.triangleExclamation,
                          ),
                          const SizedBox(height: 12),
                          ...overBudgets
                              .take(3)
                              .map(
                                (budget) => _buildAlertCard(
                                  context,
                                  '${budget.category} Over Budget',
                                  'Spent ₹${budget.spentAmount.toStringAsFixed(0)} of ₹${budget.allocatedAmount.toStringAsFixed(0)}',
                                  FontAwesomeIcons.circleExclamation,
                                  AppTheme.errorColor,
                                ),
                              ),
                          const SizedBox(height: 24),
                        ],

                        // Active Budgets Summary
                        if (activeBudgets.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Budget Overview',
                            FontAwesomeIcons.piggyBank,
                          ),
                          const SizedBox(height: 12),
                          _buildBudgetOverview(context, activeBudgets),
                          const SizedBox(height: 24),
                        ],

                        // Upcoming Events
                        if (upcomingEvents.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  context,
                                  'Upcoming Events',
                                  FontAwesomeIcons.calendarDay,
                                ),
                              ),
                              if (upcomingEvents.length > 2)
                                TextButton(
                                  onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const FinancialCalendarScreen(),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'See More',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...upcomingEvents
                              .take(2)
                              .map(
                                (event) => _buildAlertCard(
                                  context,
                                  event.title,
                                  DateFormat(
                                    'MMM d, yyyy',
                                  ).format(event.startDate),
                                  FontAwesomeIcons.calendar,
                                  AppTheme.accentColor,
                                ),
                              ),
                          const SizedBox(height: 24),
                        ],

                        // Upcoming Reminders
                        if (upcomingReminders.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionHeader(
                                  context,
                                  'Upcoming Bills & Reminders',
                                  FontAwesomeIcons.bell,
                                ),
                              ),
                              if (upcomingReminders.length > 2)
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                    context,
                                    '/reminders',
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        'See More',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        size: 12,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...upcomingReminders
                              .take(2)
                              .map(
                                (reminder) => _buildAlertCard(
                                  context,
                                  reminder.title,
                                  'Due: ${DateFormat('MMM d').format(reminder.dueDate)}${reminder.amount != null ? " • ₹${reminder.amount!.toStringAsFixed(0)}" : ""}',
                                  FontAwesomeIcons.clockRotateLeft,
                                  AppTheme.warningColor,
                                ),
                              ),
                          const SizedBox(height: 24),
                        ],

                        // Shopping List Preview
                        if (shoppingItems.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Shopping List',
                            FontAwesomeIcons.cartShopping,
                          ),
                          const SizedBox(height: 12),
                          _buildShoppingPreview(context, shoppingItems),
                          const SizedBox(height: 24),
                        ],

                        // Savings Goals Progress
                        _buildSectionHeader(
                          context,
                          'Savings Goals',
                          FontAwesomeIcons.bullseye,
                        ),
                        const SizedBox(height: 12),
                        _buildSavingsGoalsPreview(context, savingsProvider),

                        const SizedBox(height: 24),

                        // Other Alerts
                        if (overdueTasks.isNotEmpty ||
                            upcomingVisits.isNotEmpty) ...[
                          _buildSectionHeader(
                            context,
                            'Other Alerts',
                            FontAwesomeIcons.bellConcierge,
                          ),
                          const SizedBox(height: 12),

                          if (overdueTasks.isNotEmpty)
                            _buildAlertCard(
                              context,
                              'Overdue Tasks',
                              '${overdueTasks.length} task${overdueTasks.length > 1 ? 's' : ''} need attention',
                              FontAwesomeIcons.triangleExclamation,
                              AppTheme.warningColor,
                            ),

                          if (upcomingVisits.isNotEmpty)
                            _buildAlertCard(
                              context,
                              'Upcoming Health Visit',
                              upcomingVisits.first.description ??
                                  'Doctor appointment',
                              FontAwesomeIcons.heartPulse,
                              AppTheme.healthColor,
                            ),

                          const SizedBox(height: 24),
                        ],

                        // Recent Expenses
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildSectionHeader(
                                context,
                                'Recent Expenses',
                                FontAwesomeIcons.receipt,
                              ),
                            ),
                            if (recentExpenses.length > 3)
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/expenses'),
                                child: Row(
                                  children: [
                                    Text(
                                      'See More',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (recentExpenses.isEmpty)
                          _buildEmptyState(
                            context,
                            'No expenses yet',
                            'Start tracking your family expenses',
                          )
                        else
                          ...recentExpenses
                              .take(3)
                              .map(
                                (expense) =>
                                    RecentExpenseCard(expense: expense),
                              ),

                        const SizedBox(height: 24),

                        // Today's Tasks
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: _buildSectionHeader(
                                context,
                                'Today\'s Tasks',
                                FontAwesomeIcons.listCheck,
                              ),
                            ),
                            if (todayTasks.length > 3)
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/tasks'),
                                child: Row(
                                  children: [
                                    Text(
                                      'See More',
                                      style: TextStyle(
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        if (todayTasks.isEmpty)
                          _buildEmptyState(
                            context,
                            'No tasks for today',
                            'You\'re all caught up!',
                          )
                        else
                          ...todayTasks
                              .take(3)
                              .map((task) => TaskItem(task: task)),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickActionButton(
            context,
            'Add Income',
            FontAwesomeIcons.moneyBillTrendUp,
            AppTheme.successColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IncomeScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            context,
            'Set Budget',
            FontAwesomeIcons.piggyBank,
            AppTheme.primaryColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BudgetScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            context,
            'Shopping',
            FontAwesomeIcons.cartShopping,
            AppTheme.warningColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            context,
            'Reminders',
            FontAwesomeIcons.bell,
            AppTheme.accentColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReminderScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
            context,
            'Reports',
            FontAwesomeIcons.chartLine,
            AppTheme.healthColor,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ReportsScreen()),
            ),
          ),
          const SizedBox(width: 12),
          _buildQuickActionButton(
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
          const SizedBox(width: 12),
          _buildQuickActionButton(
            context,
            'Add Task',
            FontAwesomeIcons.listCheck,
            Colors.orange,
            () => showDialog(
              context: context,
              builder: (_) => const AddTaskDialog(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            FaIcon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyMembers(BuildContext context) {
    return Consumer<FamilyProvider>(
      builder: (context, provider, child) {
        if (provider.members.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              context,
              'Family Members',
              FontAwesomeIcons.peopleGroup,
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.members.length,
                itemBuilder: (context, index) {
                  final member = provider.members[index];
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: member.avatarColor != null
                              ? Color(int.parse(member.avatarColor!))
                              : AppTheme.primaryColor.withValues(alpha: 0.2),
                          child: Text(
                            member.name[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: member.avatarColor != null
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          member.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBudgetOverview(BuildContext context, List budgets) {
    final onTrack = budgets.where((b) => !b.isOverBudget).length;
    final overBudget = budgets.where((b) => b.isOverBudget).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.accentColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBudgetStat(
            context,
            '$onTrack',
            'On Track',
            AppTheme.successColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          _buildBudgetStat(
            context,
            '$overBudget',
            'Over Budget',
            AppTheme.errorColor,
          ),
          Container(
            width: 1,
            height: 40,
            color: Theme.of(context).dividerColor,
          ),
          _buildBudgetStat(
            context,
            '${budgets.length}',
            'Total',
            AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetStat(
    BuildContext context,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildShoppingPreview(BuildContext context, List items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.cartShopping,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${items.length} items to buy',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 16),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShoppingListScreen()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items
              .take(3)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.name,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      if (item.estimatedPrice != null)
                        Text(
                          '₹${item.estimatedPrice!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
          if (items.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '+ ${items.length - 3} more items',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(
            icon,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildSavingsGoalsPreview(
    BuildContext context,
    SavingsGoalProvider provider,
  ) {
    final goals = provider.goals.where((g) => !g.isCompleted).take(2).toList();

    if (goals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.bullseye,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'No active savings goals',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SavingsGoalsScreen()),
              ),
              child: const Text('Add Goal'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: goals.map((goal) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.successColor.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(goal.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      goal.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Text(
                    '${goal.percentageCompleted.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: goal.percentageCompleted / 100,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.successColor,
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '${goal.daysRemaining} days left',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAlertCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
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
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
