import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/financial_data_manager.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/expense.dart';
import '../models/income.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

          if (totalIncome == 0 && totalExpenses == 0) {
            return _buildEmptyState(context);
          }

          return CustomScrollView(
            slivers: [
              _buildAnimatedAppBar(context),
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTimePeriodFilter(),
                        const SizedBox(height: 24),
                        _buildSummaryCards(totalIncome, totalExpenses),
                        const SizedBox(height: 24),
                        _buildFinancialHealthScore(financialManager),
                        const SizedBox(height: 24),
                        _buildIncomeExpenseChart(totalIncome, totalExpenses),
                        const SizedBox(height: 24),
                        if (categoryExpenses.isNotEmpty) ...[
                          _buildSectionHeader('Expense Breakdown'),
                          const SizedBox(height: 16),
                          _buildCategoryPieChart(
                            categoryExpenses,
                            totalExpenses,
                          ),
                          const SizedBox(height: 16),
                          _buildCategoryLegend(categoryExpenses, totalExpenses),
                          const SizedBox(height: 24),
                        ],
                        if (categoryExpenses.isNotEmpty) ...[
                          _buildSectionHeader('Top Spending Categories'),
                          const SizedBox(height: 16),
                          _buildTopCategories(categoryExpenses),
                          const SizedBox(height: 24),
                        ],
                        _buildSectionHeader('Daily Spending Trend'),
                        const SizedBox(height: 16),
                        _buildDailySpendingChart(financialManager),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Monthly Comparison'),
                        const SizedBox(height: 16),
                        _buildMonthlyComparison(financialManager),
                        const SizedBox(height: 24),
                        _buildSectionHeader('6-Month Trend'),
                        const SizedBox(height: 16),
                        _buildSixMonthTrend(financialManager),
                        const SizedBox(height: 24),
                        _buildSectionHeader('Yearly Overview'),
                        const SizedBox(height: 16),
                        _buildYearlyOverview(financialManager),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActions(context),
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
            color: AppTheme.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No financial data yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding income and expenses to see reports',
            style: Theme.of(context).textTheme.bodyMedium,
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
        title: const Text(
          'Financial Reports',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        background: Container(
          decoration: BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
      ),
      actions: [
        IconButton(
          icon: const FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            color: Colors.white,
          ),
          tooltip: 'AI Analysis',
          onPressed: () => _showAIReport(context),
        ),
        IconButton(
          icon: const Icon(Icons.file_download, color: Colors.white),
          tooltip: 'Export Report',
          onPressed: () => _exportReport(context),
        ),
      ],
    );
  }

  Widget _buildTimePeriodFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: TimePeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(_getPeriodLabel(period)),
              onSelected: (selected) {
                setState(() {
                  _selectedPeriod = period;
                });
              },
              backgroundColor: Theme.of(context).cardColor,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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

  Widget _buildSummaryCards(double totalIncome, double totalExpenses) {
    final balance = totalIncome - totalExpenses;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Income',
            totalIncome,
            Icons.trending_up,
            AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Expenses',
            totalExpenses,
            Icons.trending_down,
            AppTheme.errorColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Balance',
            balance,
            Icons.account_balance_wallet,
            balance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          FittedBox(
            child: Text(
              '₹${amount.abs().toStringAsFixed(0)}',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialHealthScore(FinancialDataManager manager) {
    final score = manager.getFinancialHealthScore();
    final scoreColor = score >= 70
        ? AppTheme.successColor
        : score >= 40
        ? AppTheme.warningColor
        : AppTheme.errorColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            scoreColor.withValues(alpha: 0.2),
            scoreColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scoreColor.withValues(alpha: 0.5), width: 2),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: scoreColor.withValues(alpha: 0.2),
            ),
            child: Center(
              child: Text(
                '${score.toInt()}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: scoreColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health Score',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _getHealthMessage(score),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    color: scoreColor,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthMessage(double score) {
    if (score >= 70) return 'Excellent! Keep it up!';
    if (score >= 40) return 'Good, but room for improvement';
    return 'Needs attention';
  }

  Widget _buildIncomeExpenseChart(double totalIncome, double totalExpenses) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY:
              (totalIncome > totalExpenses ? totalIncome : totalExpenses) * 1.2,
          barTouchData: BarTouchData(enabled: false),
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
                      style: Theme.of(context).textTheme.bodySmall,
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
                  width: 40,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalExpenses,
                  color: AppTheme.errorColor,
                  width: 40,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 24,
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(
    Map<String, double> categoryExpenses,
    double totalExpenses,
  ) {
    return SizedBox(
      height: 250,
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
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: _showingSections(categoryExpenses, totalExpenses),
        ),
      ),
    );
  }

  List<PieChartSectionData> _showingSections(
    Map<String, double> data,
    double total,
  ) {
    int i = 0;
    return data.entries.map((entry) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 18.0 : 12.0;
      final radius = isTouched ? 120.0 : 100.0;
      final percentage = (entry.value / total * 100);
      final color = AppTheme.getCategoryColor(entry.key);
      i++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildCategoryLegend(
    Map<String, double> categoryExpenses,
    double totalExpenses,
  ) {
    return Column(
      children: categoryExpenses.entries.map((entry) {
        final color = AppTheme.getCategoryColor(entry.key);
        final percentage = (entry.value / totalExpenses * 100);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '₹${entry.value.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopCategories(Map<String, double> categoryExpenses) {
    final sorted = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top5 = sorted.take(5).toList();

    return Column(
      children: top5.map((entry) {
        final color = AppTheme.getCategoryColor(entry.key);
        final maxValue = sorted.first.value;
        final percentage = (entry.value / maxValue);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
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
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        entry.key,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Text(
                    '₹${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.2),
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

  Widget _buildDailySpendingChart(FinancialDataManager manager) {
    final dailyData = manager.getDailySpending(days: 30);

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1000,
            getDrawingHorizontalLine: (value) {
              return FlLine(color: AppTheme.borderColor, strokeWidth: 1);
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 5,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < dailyData.length) {
                    final date = dailyData[index]['date'] as DateTime;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat('d').format(date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  }
                  return const Text('');
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
                    AppTheme.primaryColor.withValues(alpha: 0.3),
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
    );
  }

  Widget _buildMonthlyComparison(FinancialDataManager manager) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month, 1);
    final lastMonth = DateTime(now.year, now.month - 1, 1);

    final thisMonthExpense = manager.getExpensesForMonth(thisMonth);
    final lastMonthExpense = manager.getExpensesForMonth(lastMonth);
    final diff = thisMonthExpense - lastMonthExpense;
    final percent = lastMonthExpense == 0
        ? 0.0
        : (diff / lastMonthExpense * 100);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMonthColumn(
                'Last Month',
                lastMonthExpense,
                AppTheme.textSecondary,
              ),
              Container(width: 1, height: 50, color: AppTheme.borderColor),
              _buildMonthColumn(
                'This Month',
                thisMonthExpense,
                AppTheme.primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                diff > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                color: diff > 0 ? AppTheme.errorColor : AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.abs().toStringAsFixed(1)}% ${diff > 0 ? 'increase' : 'decrease'}',
                style: TextStyle(
                  color: diff > 0 ? AppTheme.errorColor : AppTheme.successColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthColumn(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSixMonthTrend(FinancialDataManager manager) {
    final now = DateTime.now();
    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final income = manager.getIncomeForMonth(month);
      final expense = manager.getExpensesForMonth(month);

      incomeSpots.add(FlSpot((5 - i).toDouble(), income));
      expenseSpots.add(FlSpot((5 - i).toDouble(), expense));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.now().subtract(
                    Duration(days: 30 * (5 - value.toInt())),
                  );
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  );
                },
                interval: 1,
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
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: incomeSpots,
              isCurved: true,
              color: AppTheme.successColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.successColor.withValues(alpha: 0.1),
              ),
            ),
            LineChartBarData(
              spots: expenseSpots,
              isCurved: true,
              color: AppTheme.errorColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.errorColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyOverview(FinancialDataManager manager) {
    final now = DateTime.now();
    final yearIncome = manager.getIncomeForYear(now.year);
    final yearExpense = manager.getExpensesForYear(now.year);
    final yearBalance = yearIncome - yearExpense;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.2),
            AppTheme.accentColor.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            '${now.year} Overview',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildYearStat('Income', yearIncome, AppTheme.successColor),
              Container(width: 1, height: 60, color: AppTheme.borderColor),
              _buildYearStat('Expenses', yearExpense, AppTheme.errorColor),
              Container(width: 1, height: 60, color: AppTheme.borderColor),
              _buildYearStat(
                'Balance',
                yearBalance,
                yearBalance >= 0 ? AppTheme.successColor : AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearStat(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 8),
        Text(
          '₹${(amount / 1000).toStringAsFixed(1)}K',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActions(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          heroTag: 'ai_report',
          onPressed: () => _showAIReport(context),
          backgroundColor: AppTheme.primaryColor,
          child: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
        ),
        const SizedBox(height: 12),
        FloatingActionButton(
          heroTag: 'export',
          onPressed: () => _exportReport(context),
          backgroundColor: AppTheme.accentColor,
          child: const Icon(Icons.file_download),
        ),
      ],
    );
  }

  void _exportReport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppTheme.infoColor,
      ),
    );
  }

  void _showAIReport(BuildContext context) async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final financialManager = Provider.of<FinancialDataManager>(
      context,
      listen: false,
    );

    final aiStatus = await geminiService.getAIStatus();
    if (!aiStatus['ready']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI features are not enabled. Please check settings.',
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final thisMonthEnd = DateTime(now.year, now.month + 1, 0);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0);

      final totalIncome = financialManager.getIncomeByPeriod(
        thisMonthStart,
        thisMonthEnd,
      );

      final totalExpenses = financialManager
          .getExpensesByDateRange(thisMonthStart, thisMonthEnd)
          .fold(0.0, (sum, e) => sum + e.amount);

      final lastMonthIncome = financialManager.getIncomeByPeriod(
        lastMonthStart,
        lastMonthEnd,
      );

      final lastMonthExpenses = financialManager
          .getExpensesByDateRange(lastMonthStart, lastMonthEnd)
          .fold(0.0, (sum, e) => sum + e.amount);

      final thisMonthExpensesList = financialManager.getExpensesByDateRange(
        thisMonthStart,
        thisMonthEnd,
      );

      Map<String, double> categoryExpenses = {};
      for (var expense in thisMonthExpensesList) {
        categoryExpenses[expense.category] =
            (categoryExpenses[expense.category] ?? 0) + expense.amount;
      }

      final report = await geminiService.generateReportInsights(
        totalIncome: totalIncome,
        totalExpenses: totalExpenses,
        categoryExpenses: categoryExpenses,
        lastMonthIncome: lastMonthIncome,
        lastMonthExpenses: lastMonthExpenses,
      );

      if (context.mounted) {
        Navigator.pop(context);
        _showReportDialog(context, report);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate report: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showReportDialog(BuildContext context, String report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Financial Report',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: MarkdownBody(
                  data: report,
                  styleSheet: MarkdownStyleSheet(
                    h1: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    h2: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    h3: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    p: const TextStyle(fontSize: 16, height: 1.5),
                    listBullet: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Share feature coming soon!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share Report'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
