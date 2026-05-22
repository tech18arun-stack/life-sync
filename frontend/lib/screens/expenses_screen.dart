import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../providers/financial_data_manager.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../widgets/add_expense_dialog.dart';
import '../services/startio_ads.dart';
import '../services/gemini_service.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  String _selectedPeriod = 'Month';
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final financialManager = Provider.of<FinancialDataManager>(context);

    // Theme Helpers
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    // Get expenses based on selected period
    final now = DateTime.now();
    final expenses = financialManager.expenses.where((expense) {
      switch (_selectedPeriod) {
        case 'Day':
          return expense.date.year == now.year &&
              expense.date.month == now.month &&
              expense.date.day == now.day;
        case 'Week':
          final weekAgo = now.subtract(const Duration(days: 7));
          return expense.date.isAfter(weekAgo);
        case 'Month':
          return expense.date.year == now.year &&
              expense.date.month == now.month;
        case 'Year':
          return expense.date.year == now.year;
        default:
          return true;
      }
    }).toList();

    // Filter by search and category
    final filteredExpenses = expenses.where((expense) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          expense.category.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.description.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == 'All' || expense.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    // Calculations
    final total = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final categoryExpenses = <String, double>{};
    for (final expense in filteredExpenses) {
      categoryExpenses[expense.category] =
          (categoryExpenses[expense.category] ?? 0) + expense.amount;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        bottomNavigationBar: const StartioBanner(),
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textPrimary),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            'Expenses',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -1,
            ),
          ),
          centerTitle: false,
          actions: [
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.chartPie,
                color: textPrimary,
                size: 20,
              ),
              tooltip: 'Charts',
              onPressed: () =>
                  _showChartsDialog(context, categoryExpenses, total),
            ),
            IconButton(
              icon: FaIcon(
                FontAwesomeIcons.fileExport,
                color: textPrimary,
                size: 20,
              ),
              tooltip: 'Export',
              onPressed: () => _showExportOptions(context),
            ),
          ],
          bottom: TabBar(
            labelColor: AppTheme.primaryColor,
            unselectedLabelColor: textSecondary,
            indicatorColor: AppTheme.primaryColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'List'),
              Tab(text: 'Categories'),
              Tab(text: 'Recent'),
            ],
          ),
        ),
        body: Column(
          children:
              [
                    // Search and Summary Container
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          // Search Bar with improved design
                          Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  setState(() => _searchQuery = value),
                              style: GoogleFonts.inter(color: textPrimary),
                              decoration: InputDecoration(
                                hintText: 'Search expenses...',
                                hintStyle: GoogleFonts.inter(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  Icons.search,
                                  color: textSecondary,
                                  size: 20,
                                ),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.clear,
                                          color: textSecondary,
                                          size: 18,
                                        ),
                                        onPressed: () =>
                                            setState(() => _searchQuery = ''),
                                      )
                                    : null,
                                filled: true,
                                fillColor: cardColor,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.grey.withOpacity(0.1),
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Filter Row - Chip-like style
                          Row(
                            children: [
                              _buildFilterChip(
                                label: _selectedPeriod,
                                icon: Icons.calendar_today,
                                onTap: () => _showPeriodPicker(context),
                                textPrimary: textPrimary,
                                cardColor: cardColor,
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: _selectedCategory,
                                icon: Icons.category_outlined,
                                onTap: () => _showCategoryPicker(
                                  context,
                                  categoryExpenses.keys.toList(),
                                ),
                                textPrimary: textPrimary,
                                cardColor: cardColor,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Premium Total Card (Aligned with Home Screen style)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: AppTheme.sunsetGradient,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.errorColor.withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  right: -10,
                                  top: -10,
                                  child: Icon(
                                    Icons.trending_down,
                                    color: Colors.white.withOpacity(0.1),
                                    size: 80,
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total Spent',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${NumberFormat('#,##,##0.00', 'en_IN').format(total)}',
                                      style: GoogleFonts.inter(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        '${filteredExpenses.length} transactions',
                                        style: GoogleFonts.inter(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content List
                    Expanded(
                      child: filteredExpenses.isEmpty
                          ? _buildEmptyState(
                              context,
                              textPrimary,
                              textSecondary,
                            )
                          : TabBarView(
                              children: [
                                _buildExpenseList(
                                  filteredExpenses,
                                  financialManager,
                                  context,
                                ),
                                _buildCategoriesView(
                                  categoryExpenses,
                                  total,
                                  context,
                                ),
                                _buildRecentView(
                                  filteredExpenses,
                                  financialManager,
                                  context,
                                ),
                              ],
                            ),
                    ),
                  ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.1, curve: Curves.easeOutQuad),
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) => const AddExpenseDialog(),
            );
            await StartIOAds.showInterstitial(context);
          },
          icon: const FaIcon(FontAwesomeIcons.plus),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }

  Widget _buildExpenseList(
    List<Expense> expenses,
    FinancialDataManager provider,
    BuildContext context,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length + (expenses.length > 5 ? 1 : 0),
      itemBuilder: (context, index) {
        if (expenses.length > 5 && index == 3) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: StartioMrec()),
          );
        }
        final expenseIndex = (expenses.length > 5 && index > 3)
            ? index - 1
            : index;
        return _buildTransactionItem(context, expenses[expenseIndex], provider)
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Expense expense,
    FinancialDataManager provider,
  ) {
    final color = AppTheme.getCategoryColor(expense.category);
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Dismissible(
      key: Key(expense.id ?? ''),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context),
      onDismissed: (_) {
        provider.deleteExpense(expense.id ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Expense deleted'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () => provider.addExpense(expense),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
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
                AppTheme.getCategoryIcon(expense.category),
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: textPrimary,
                    ),
                  ),
                  if (expense.description.isNotEmpty)
                    Text(
                      expense.description,
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    DateFormat('MMM d, h:mm a').format(expense.date),
                    style: GoogleFonts.inter(
                      color: textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '-₹${NumberFormat('#,##,##0').format(expense.amount)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentView(
    List<Expense> expenses,
    FinancialDataManager provider,
    BuildContext context,
  ) {
    final recent = expenses.take(15).toList();
    return _buildExpenseList(recent, provider, context);
  }

  Widget _buildCategoriesView(
    Map<String, double> categoryExpenses,
    double total,
    BuildContext context,
  ) {
    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final percentage = total > 0 ? (entry.value / total) * 100 : 0.0;
        return _buildCategoryCard(context, entry.key, entry.value, percentage)
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideX(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String category,
    double amount,
    double percentage,
  ) {
    final color = AppTheme.getCategoryColor(category);
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  AppTheme.getCategoryIcon(category),
                  color: color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage / 100,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '₹${NumberFormat('#,##,##0').format(amount)}',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.receipt,
            size: 48,
            color: textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required Color textPrimary,
    required Color cardColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.inter(
                    color: textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: textPrimary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPeriodPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Day', 'Week', 'Month', 'Year'].map((p) {
            final isSelected = _selectedPeriod == p;
            return ListTile(
              title: Text(
                p,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedPeriod = p);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showCategoryPicker(BuildContext context, List<String> categories) {
    final allCats = {
      'All',
      ...categories,
      'Food',
      'Transport',
      'Health',
      'Education',
      'Entertainment',
      'Utilities',
      'Shopping',
      'Rent',
      'Insurance',
      'Groceries',
      'Dining Out',
      'Travel',
      'Personal Care',
      'Gifts',
      'Investments',
      'Others',
    }.toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (context, scrollController) => ListView.builder(
          controller: scrollController,
          itemCount: allCats.length,
          itemBuilder: (context, index) {
            final cat = allCats[index];
            final isSelected = _selectedCategory == cat;
            return ListTile(
              leading: Icon(
                cat == 'All'
                    ? Icons.all_inclusive
                    : AppTheme.getCategoryIcon(cat),
                color: isSelected ? AppTheme.primaryColor : null,
              ),
              title: Text(
                cat,
                style: GoogleFonts.inter(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? AppTheme.primaryColor : null,
                ),
              ),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedCategory = cat);
                Navigator.pop(context);
              },
            );
          },
        ),
      ),
    );
  }

  void _showChartsDialog(
    BuildContext context,
    Map<String, double> data,
    double total,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Expense Breakdown',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
          ),
        ),
        content: SizedBox(
          height: 320,
          width: 320,
          child: data.isEmpty
              ? const Center(child: Text('No Data'))
              : Column(
                  children: [
                    Expanded(
                      child: PieChart(
                        PieChartData(
                          sections: data.entries.map((e) {
                            final pct = total > 0 ? (e.value / total) * 100 : 0;
                            return PieChartSectionData(
                              color: AppTheme.getCategoryColor(e.key),
                              value: e.value,
                              title: '${pct.toStringAsFixed(0)}%',
                              radius: 50,
                              titleStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            );
                          }).toList(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Total: ₹${total.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
        ),
        actions: [
          IconButton(
            icon: const FaIcon(
              FontAwesomeIcons.brain,
              color: AppTheme.accentColor,
              size: 18,
            ),
            onPressed: () => _getAIInsight(context, data, total),
            tooltip: 'Get AI Insight',
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _getAIInsight(
    BuildContext context,
    Map<String, double> data,
    double total,
  ) async {
    final gemini = Provider.of<GeminiService>(context, listen: false);
    final isEnabled = await gemini.isAIEnabled();

    if (!isEnabled) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('AI Features are disabled. Enable them in Settings.'),
        ),
      );
      return;
    }

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const FaIcon(
              FontAwesomeIcons.brain,
              color: AppTheme.accentColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              'AI Insight',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: FutureBuilder<String>(
          future: gemini.analyzeBudgetPerformance(
            budgets: Provider.of<FinancialDataManager>(
              context,
              listen: false,
            ).budgets,
            totalIncome: Provider.of<FinancialDataManager>(
              context,
              listen: false,
            ).getTotalIncome(),
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }
            return SingleChildScrollView(
              child: Text(
                snapshot.data ?? 'No insight available',
                style: GoogleFonts.inter(fontSize: 14),
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Expenses',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.file_copy_outlined, color: Colors.red),
              title: const Text('Export as PDF'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(
                Icons.table_view_outlined,
                color: Colors.green,
              ),
              title: const Text('Export as CSV'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Expense?'),
        content: const Text('This will permanently remove this record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
