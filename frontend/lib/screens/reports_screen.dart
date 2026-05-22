import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../services/gemini_service.dart';
import '../providers/theme_provider.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../services/startio_ads.dart';
import '../providers/auth_provider.dart';
import '../widgets/premium_gate.dart';
import 'package:flutter_animate/flutter_animate.dart';

enum TimePeriod { week, month, threeMonths, sixMonths, year, all }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with TickerProviderStateMixin {
  int _touchedIndex = -1;
  TimePeriod _selectedPeriod = TimePeriod.month;
  String? _selectedCategory;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  DateTimeRange _getDateRange() {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case TimePeriod.week:
        return DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case TimePeriod.month:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        );
      case TimePeriod.threeMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: now,
        );
      case TimePeriod.sixMonths:
        return DateTimeRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: now,
        );
      case TimePeriod.year:
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        );
      case TimePeriod.all:
        return DateTimeRange(start: DateTime(2000, 1, 1), end: now);
    }
  }

  List<Expense> _getFilteredExpenses(
    FinancialDataManager manager,
    DateTimeRange range,
  ) {
    return manager.expenses.where((e) {
      return e.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  List<Income> _getFilteredIncome(
    FinancialDataManager manager,
    DateTimeRange range,
  ) {
    return manager.incomes.where((i) {
      return i.date.isAfter(range.start.subtract(const Duration(days: 1))) &&
          i.date.isBefore(range.end.add(const Duration(days: 1)));
    }).toList();
  }

  Map<String, double> _getCategoryExpenses(List<Expense> expenses) {
    Map<String, double> categoryExpenses = {};
    for (var expense in expenses) {
      if (_selectedCategory == null || expense.category == _selectedCategory) {
        categoryExpenses[expense.category] =
            (categoryExpenses[expense.category] ?? 0) + expense.amount;
      }
    }
    return categoryExpenses;
  }

  // --- AI Report Logic ---
  Future<void> _showAIReport(BuildContext context) async {
    final manager = Provider.of<FinancialDataManager>(context, listen: false);

    final geminiService = Provider.of<GeminiService>(context, listen: false);

    // Check if AI enabled
    if (!await geminiService.isAIEnabled()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enable AI features in Settings first'),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Calculate report data
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);

      final totalIncome = manager.getIncomeForMonth(now);
      final totalExpenses = manager.getExpensesForMonth(now);
      final lastTotalIncome = manager.getIncomeForMonth(lastMonth);
      final lastTotalExpenses = manager.getExpensesForMonth(lastMonth);

      final monthExpenses = manager.getExpensesByDateRange(
        DateTime(now.year, now.month, 1),
        DateTime(now.year, now.month + 1, 0),
      );
      final Map<String, double> categoryExpenses = {};
      for (var e in monthExpenses) {
        categoryExpenses[e.category] =
            (categoryExpenses[e.category] ?? 0) + e.amount;
      }

      final report = await geminiService.generateReportInsights(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        categoryExpenses: categoryExpenses,
        lastMonthIncome: lastTotalIncome,
        lastMonthExpenses: lastTotalExpenses,
      );

      if (!context.mounted) return;
      Navigator.pop(context); // Close loading

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.wandMagicSparkles,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI Insights',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Markdown(
                    data: report,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.inter(fontSize: 14, height: 1.5),
                      h1: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      h2: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      listBullet: GoogleFonts.inter(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to generate report: $e')));
    }
  }

  void _exportReport(BuildContext context) {
    // Placeholder for export functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exporting Report...')));
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: isDark
          ? AppTheme.backgroundColor
          : const Color(0xFFF7F9FC),
      bottomNavigationBar: const StartioBanner(),
      body: Consumer<FinancialDataManager>(
        builder: (context, financialManager, child) {
          final dateRange = _getDateRange();
          final filteredExpenses = _getFilteredExpenses(
            financialManager,
            dateRange,
          );
          final filteredIncome = _getFilteredIncome(
            financialManager,
            dateRange,
          );

          final totalIncome = filteredIncome.fold(
            0.0,
            (sum, i) => sum + i.amount,
          );
          final totalExpenses = filteredExpenses.fold(
            0.0,
            (sum, e) => sum + e.amount,
          );
          final categoryExpenses = _getCategoryExpenses(filteredExpenses);

          // Get previous month balance (carry forward)
          final previousMonthBalance = financialManager
              .getPreviousMonthClosingBalance();
          final hasHistoricalData = financialManager.hasAnyHistoricalData();
          final hasCurrentMonthData = financialManager.hasCurrentMonthData();

          // Show empty state only if there's NO historical data at all
          if (!hasHistoricalData) {
            return CustomScrollView(
              slivers: [
                _buildAnimatedAppBar(context),
                SliverFillRemaining(child: _buildEmptyState(context)),
              ],
            );
          }

          // If no current month data but has historical data, show previous month summary
          if (!hasCurrentMonthData) {
            return CustomScrollView(
              slivers: [
                _buildAnimatedAppBar(context),
                SliverToBoxAdapter(
                  child: ResponsiveWrapper(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPreviousMonthSummary(context, financialManager),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 40,
                                    color: AppTheme.primaryColor,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No transactions for this month yet',
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.getFontSize(
                                        context,
                                        FontSizeType.title,
                                      ),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Your previous month\'s balance of ₹${previousMonthBalance.toStringAsFixed(0)} will be carried forward as opening balance.',
                                    style: GoogleFonts.inter(
                                      fontSize: Responsive.getFontSize(
                                        context,
                                        FontSizeType.body,
                                      ),
                                      color: AppTheme.textSecondary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return CustomScrollView(
            slivers: [
              _buildAnimatedAppBar(context),
              SliverToBoxAdapter(
                child: ResponsiveWrapper(
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.getHorizontalPadding(context),
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTimePeriodFilter(context),
                          const SizedBox(height: 24),
                          _buildSummaryCards(
                            context,
                            totalIncome,
                            totalExpenses,
                            previousMonthBalance,
                          ),
                          const SizedBox(height: 24),
                          _buildFinancialHealthScore(financialManager, context),
                          const SizedBox(height: 24),
                          _buildSectionHeader('Income vs Expenses', context),
                          const SizedBox(height: 16),
                          _buildIncomeExpenseChart(
                            context,
                            totalIncome,
                            totalExpenses,
                          ),
                          const SizedBox(height: 24),
                          const Center(child: StartioMrec()),
                          const SizedBox(height: 24),
                          if (categoryExpenses.isNotEmpty) ...[
                            _buildSectionHeader('Expense Breakdown', context),
                            const SizedBox(height: 16),
                            _buildCategoryPieChart(
                              categoryExpenses,
                              totalExpenses,
                            ),
                            const SizedBox(height: 16),
                            _buildCategoryLegend(
                              context,
                              categoryExpenses,
                              totalExpenses,
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (categoryExpenses.isNotEmpty) ...[
                            _buildSectionHeader(
                              'Top Spending Categories',
                              context,
                            ),
                            const SizedBox(height: 16),
                            _buildTopCategories(context, categoryExpenses),
                            const SizedBox(height: 24),
                          ],
                          _buildSectionHeader('Daily Spending Trend', context),
                          const SizedBox(height: 16),
                          _buildDailySpendingChart(context, financialManager),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.chartPie,
            size: 80,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No financial data yet',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding income and expenses to see reports',
            style: GoogleFonts.inter(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviousMonthSummary(
    BuildContext context,
    FinancialDataManager manager,
  ) {
    final previousMonthBalance = manager.getPreviousMonthClosingBalance();
    final previousMonthIncome = manager.getPreviousMonthIncome();
    final previousMonthExpenses = manager.getPreviousMonthExpenses();
    final netBalance = previousMonthIncome - previousMonthExpenses;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                'Previous Month Summary',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Income',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${previousMonthIncome.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Expenses',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${previousMonthExpenses.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Net',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${netBalance.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: netBalance >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Closing Balance',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '₹${previousMonthBalance.toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: previousMonthBalance >= 0
                        ? AppTheme.primaryColor
                        : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Financial Reports',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            color: Colors.white,
            size: 20,
          ),
          tooltip: 'AI Analysis',
          onPressed: () {
            // Check Premium or Gate
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.currentUser?.isPremiumActive == true) {
              _showAIReport(context);
            } else {
              // Push Premium Gate Screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PremiumGate(
                    featureName: 'AI Detailed Reports',
                    icon: FontAwesomeIcons.wandMagicSparkles,
                    requiredAds: 3,
                    child: _ReportsAIPassthrough(
                      onReady: () => _showAIReport(context),
                    ),
                  ),
                ),
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          tooltip: 'Export Report',
          onPressed: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            if (auth.currentUser?.isPremiumActive == true) {
              _exportReport(context);
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => PremiumGate(
                    featureName: 'Export PDF Reports',
                    icon: Icons.download_rounded,
                    requiredAds: 3,
                    child: _ReportsExportPassthrough(
                      onExport: () => _exportReport(context),
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTimePeriodFilter(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Wrap(
        spacing: 8,
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return ChoiceChip(
            selected: isSelected,
            label: Text(_getPeriodLabel(period)),
            onSelected: (selected) {
              if (selected) setState(() => _selectedPeriod = period);
            },
            selectedColor: AppTheme.primaryColor,
            backgroundColor: Theme.of(context).cardColor,
            labelStyle: GoogleFonts.inter(
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: Responsive.getFontSize(context, FontSizeType.body),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide.none,
            ),
            elevation: isSelected ? 4 : 0,
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodLabel(TimePeriod period) {
    switch (period) {
      case TimePeriod.week:
        return 'Week';
      case TimePeriod.month:
        return 'Month';
      case TimePeriod.threeMonths:
        return '3 Months';
      case TimePeriod.sixMonths:
        return '6 Months';
      case TimePeriod.year:
        return 'Year';
      case TimePeriod.all:
        return 'All Time';
    }
  }

  Widget _buildSummaryCards(
    BuildContext context,
    double totalIncome,
    double totalExpenses,
    double previousMonthBalance,
  ) {
    // Calculate current balance including previous month's balance
    final openingBalance = previousMonthBalance;
    final currentPeriodNet = totalIncome - totalExpenses;
    final closingBalance = openingBalance + currentPeriodNet;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 24 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: isSmallScreen
              ? Column(
                  children: [
                    _buildStatItem(
                      'Opening Balance',
                      openingBalance,
                      AppTheme.textSecondary,
                      Icons.history,
                      context,
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem(
                      'Income',
                      totalIncome,
                      AppTheme.successColor,
                      Icons.trending_up,
                      context,
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem(
                      'Expenses',
                      totalExpenses,
                      AppTheme.errorColor,
                      Icons.trending_down,
                      context,
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem(
                      'Closing Balance',
                      closingBalance,
                      closingBalance >= 0
                          ? AppTheme.primaryColor
                          : AppTheme.errorColor,
                      Icons.account_balance_wallet,
                      context,
                    ),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Opening Balance',
                          openingBalance,
                          AppTheme.textSecondary,
                          Icons.history,
                          context,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          'Income',
                          totalIncome,
                          AppTheme.successColor,
                          Icons.trending_up,
                          context,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatItem(
                          'Expenses',
                          totalExpenses,
                          AppTheme.errorColor,
                          Icons.trending_down,
                          context,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        _buildStatItem(
                          'Closing Balance',
                          closingBalance,
                          closingBalance >= 0
                              ? AppTheme.primaryColor
                              : AppTheme.errorColor,
                          Icons.account_balance_wallet,
                          context,
                        ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildStatItem(
    String label,
    double amount,
    Color color,
    IconData icon,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: Responsive.getIconSize(context) - 4, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: Responsive.getFontSize(context, FontSizeType.small),
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.abs().toInt()}',
          style: GoogleFonts.inter(
            fontSize: Responsive.getFontSize(context, FontSizeType.subtitle),
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHealthScore(
    FinancialDataManager manager,
    BuildContext context,
  ) {
    final score = manager.getFinancialHealthScore();
    final scoreColor = score >= 70
        ? AppTheme.successColor
        : score >= 40
        ? AppTheme.warningColor
        : AppTheme.errorColor;

    return Container(
      padding: EdgeInsets.all(Responsive.isDesktop(context) ? 28 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.15),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 600) {
            // Mobile layout
            return Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${score.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Financial Health',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: Responsive.getFontSize(
                      context,
                      FontSizeType.title,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  score >= 70
                      ? 'Excellent work! Keep maintaining your habits.'
                      : score >= 40
                      ? 'Good, but there\'s room for improvement.'
                      : 'Needs attention. Check your spending.',
                  style: GoogleFonts.inter(
                    fontSize: Responsive.getFontSize(
                      context,
                      FontSizeType.body,
                    ),
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          } else {
            // Tablet/Desktop layout
            return Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: score / 100,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${score.toInt()}',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Health',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: Responsive.getFontSize(
                            context,
                            FontSizeType.title,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        score >= 70
                            ? 'Excellent work! Keep maintaining your habits.'
                            : score >= 40
                            ? 'Good, but there\'s room for improvement.'
                            : 'Needs attention. Check your spending.',
                        style: GoogleFonts.inter(
                          fontSize: Responsive.getFontSize(
                            context,
                            FontSizeType.body,
                          ),
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title, BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: Responsive.getFontSize(context, FontSizeType.title),
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }

  Widget _buildIncomeExpenseChart(
    BuildContext context,
    double totalIncome,
    double totalExpenses,
  ) {
    return Container(
          height: Responsive.isDesktop(context) ? 260 : 220,
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 20 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY:
                  (totalIncome > totalExpenses ? totalIncome : totalExpenses) *
                  1.1,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  tooltipBgColor: Theme.of(context).cardColor,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      '${rod.toY.toInt()}',
                      GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: rod.color,
                        fontSize: Responsive.getFontSize(
                          context,
                          FontSizeType.body,
                        ),
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          value == 0 ? 'Income' : 'Expenses',
                          style: GoogleFonts.inter(
                            fontSize: Responsive.getFontSize(
                              context,
                              FontSizeType.body,
                            ),
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: totalIncome,
                      color: AppTheme.successColor,
                      width: 32,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: totalExpenses,
                      color: AppTheme.errorColor,
                      width: 32,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  Widget _buildCategoryPieChart(
    Map<String, double> categoryExpenses,
    double totalExpenses,
  ) {
    return SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex =
                        pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 4,
              centerSpaceRadius: 40,
              sections: _showingSections(categoryExpenses, totalExpenses),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }

  List<PieChartSectionData> _showingSections(
    Map<String, double> data,
    double total,
  ) {
    int i = 0;
    return data.entries.map((entry) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched
          ? 16.0
          : 0.0; // Hide labels on pie, show in legend/tooltip if needed or interactive
      final radius = isTouched ? 100.0 : 80.0;
      final percentage = (entry.value / total * 100);
      final color = AppTheme.getCategoryColor(entry.key);
      i++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: radius,
        titleStyle: GoogleFonts.inter(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        badgeWidget: isTouched
            ? Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black),
                ),
              )
            : null,
        badgePositionPercentageOffset: 1.2,
      );
    }).toList();
  }

  Widget _buildCategoryLegend(
    BuildContext context,
    Map<String, double> categoryExpenses,
    double totalExpenses,
  ) {
    return Column(
      children: categoryExpenses.entries.map((entry) {
        final color = AppTheme.getCategoryColor(entry.key);
        final percentage = (entry.value / totalExpenses * 100);
        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.isDesktop(context) ? 12 : 8,
          ),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w500,
                    fontSize: Responsive.getFontSize(
                      context,
                      FontSizeType.body,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                  fontSize: Responsive.getFontSize(context, FontSizeType.body),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '₹${entry.value.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.getFontSize(
                    context,
                    FontSizeType.subtitle,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCategories(
    BuildContext context,
    Map<String, double> categoryExpenses,
  ) {
    final sorted = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Column(
      children: top5.map((entry) {
        final color = AppTheme.getCategoryColor(entry.key);
        final maxValue = sorted.first.value;
        final percentage = (entry.value / maxValue);

        return Padding(
          padding: EdgeInsets.only(
            bottom: Responsive.isDesktop(context) ? 20 : 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppTheme.getCategoryIcon(entry.key),
                        color: color,
                        size: Responsive.getIconSize(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          fontSize: Responsive.getFontSize(
                            context,
                            FontSizeType.body,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: Responsive.getFontSize(
                        context,
                        FontSizeType.subtitle,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.1),
                  color: color,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDailySpendingChart(
    BuildContext context,
    FinancialDataManager manager,
  ) {
    final dailyData = manager.getDailySpending(days: 30);
    return Container(
          height: Responsive.isDesktop(context) ? 260 : 220,
          padding: EdgeInsets.all(Responsive.isDesktop(context) ? 24 : 20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [AppTheme.cardShadow],
          ),
          child: LineChart(
            LineChartData(
              gridData: const FlGridData(show: false),
              titlesData: const FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ), // Cleaner look without dates for sparkline effect
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(dailyData.length, (index) {
                    return FlSpot(
                      index.toDouble(),
                      (dailyData[index]['amount'] as double),
                    );
                  }),
                  isCurved: true,
                  color: AppTheme.primaryColor,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryColor.withValues(alpha: 0.2),
                        AppTheme.primaryColor.withValues(alpha: 0.0),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutBack);
  }
}

/// Helper to trigger report action immediately after unlock
class _ReportsAIPassthrough extends StatefulWidget {
  final VoidCallback onReady;
  const _ReportsAIPassthrough({required this.onReady});
  @override
  State<_ReportsAIPassthrough> createState() => _ReportsAIPassthroughState();
}

class _ReportsAIPassthroughState extends State<_ReportsAIPassthrough> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop(); // Go back from gate screen
      widget.onReady(); // Trigger feature
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _ReportsExportPassthrough extends StatefulWidget {
  final VoidCallback onExport;
  const _ReportsExportPassthrough({required this.onExport});
  @override
  State<_ReportsExportPassthrough> createState() =>
      _ReportsExportPassthroughState();
}

class _ReportsExportPassthroughState extends State<_ReportsExportPassthrough> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      widget.onExport();
    });
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
