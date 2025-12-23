import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/financial_data_manager.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../widgets/add_expense_dialog.dart';

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

    final total = filteredExpenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categoryExpenses = <String, double>{};
    for (final expense in filteredExpenses) {
      categoryExpenses[expense.category] =
          (categoryExpenses[expense.category] ?? 0) + expense.amount;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Expenses'),
          actions: [
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.chartPie),
              tooltip: 'Charts',
              onPressed: () =>
                  _showChartsDialog(context, categoryExpenses, total),
            ),
            IconButton(
              icon: const FaIcon(FontAwesomeIcons.fileExport),
              tooltip: 'Export',
              onPressed: () => _showExportOptions(context),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(icon: FaIcon(FontAwesomeIcons.list, size: 20), text: 'List'),
              Tab(
                icon: FaIcon(FontAwesomeIcons.chartColumn, size: 20),
                text: 'Categories',
              ),
              Tab(
                icon: FaIcon(FontAwesomeIcons.clockRotateLeft, size: 20),
                text: 'Recent',
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search and filter bar
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).cardColor,
              child: Column(
                children: [
                  // Search bar
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Search expenses...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _searchQuery = ''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Period selector
                      Expanded(child: _buildPeriodSelector()),
                      const SizedBox(width: 12),
                      // Category filter
                      Expanded(
                        child: _buildCategoryFilter(
                          categoryExpenses.keys.toList(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Total card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text(
                    'Total Expenses',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${filteredExpenses.length} transactions',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            // Tab content
            Expanded(
              child: filteredExpenses.isEmpty
                  ? _buildEmptyState(context)
                  : TabBarView(
                      children: [
                        _buildExpenseList(filteredExpenses, financialManager),
                        _buildCategoriesView(categoryExpenses, total),
                        _buildRecentView(filteredExpenses, financialManager),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_expense_fab',
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => const AddExpenseDialog(),
            );
          },
          icon: const FaIcon(FontAwesomeIcons.plus),
          label: const Text('Add Expense'),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedPeriod,
      decoration: InputDecoration(
        labelText: 'Period',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: ['Day', 'Week', 'Month', 'Year'].map((period) {
        return DropdownMenuItem(value: period, child: Text(period));
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedPeriod = value);
      },
    );
  }

  Widget _buildCategoryFilter(List<String> categories) {
    // Combine existing categories with new ones for the filter
    final allCategories = {
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

    // Ensure selected category is in the list, if not reset to All
    if (!allCategories.contains(_selectedCategory)) {
      _selectedCategory = 'All';
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: allCategories
          .toSet()
          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCategory = value);
      },
    );
  }

  Widget _buildExpenseList(
    List<Expense> expenses,
    FinancialDataManager provider,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        return _buildTransactionItem(context, expenses[index], provider);
      },
    );
  }

  Widget _buildCategoriesView(
    Map<String, double> categoryExpenses,
    double total,
  ) {
    final sortedEntries = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        final entry = sortedEntries[index];
        final percentage = (entry.value / total) * 100;
        return _buildCategoryCard(context, entry.key, entry.value, percentage);
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

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: FaIcon(
                  _getCategoryIcon(category),
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Text(
                '₹${amount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: color.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentView(
    List<Expense> expenses,
    FinancialDataManager provider,
  ) {
    final recentExpenses = expenses.take(20).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recentExpenses.length,
      itemBuilder: (context, index) {
        return _buildCompactTransaction(
          context,
          recentExpenses[index],
          provider,
        );
      },
    );
  }

  Widget _buildCompactTransaction(
    BuildContext context,
    Expense expense,
    FinancialDataManager provider,
  ) {
    final color = AppTheme.getCategoryColor(expense.category);

    return Dismissible(
      key: Key(expense.id ?? ''),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
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
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(
                _getCategoryIcon(expense.category),
                color: color,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (expense.description.isNotEmpty)
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${DateFormat('MMM d').format(expense.date)} • ${DateFormat('h:mm a').format(expense.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(
    BuildContext context,
    Expense expense,
    FinancialDataManager provider,
  ) {
    final color = AppTheme.getCategoryColor(expense.category);

    return Dismissible(
      key: Key(expense.id ?? ''),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Expense?'),
            content: Text(
              'Delete ${expense.category} expense of ₹${expense.amount}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: FaIcon(
                _getCategoryIcon(expense.category),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.category,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (expense.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      expense.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.calendar,
                        size: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('MMM d, yyyy').format(expense.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 8),
                      FaIcon(
                        FontAwesomeIcons.clock,
                        size: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('h:mm a').format(expense.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${expense.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'transport':
        return FontAwesomeIcons.car;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      case 'entertainment':
        return FontAwesomeIcons.film;
      case 'bills':
      case 'utilities':
        return FontAwesomeIcons.fileInvoice;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      case 'education':
        return FontAwesomeIcons.graduationCap;
      case 'rent':
        return FontAwesomeIcons.house;
      case 'insurance':
        return FontAwesomeIcons.shieldHalved;
      case 'groceries':
        return FontAwesomeIcons.basketShopping;
      case 'dining out':
        return FontAwesomeIcons.burger;
      case 'travel':
        return FontAwesomeIcons.plane;
      case 'personal care':
        return FontAwesomeIcons.spa;
      case 'gifts':
        return FontAwesomeIcons.gift;
      case 'investments':
        return FontAwesomeIcons.chartLine;
      default:
        return FontAwesomeIcons.wallet;
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            FontAwesomeIcons.receipt,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty
                ? 'No matching expenses'
                : 'No expenses yet',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Start tracking your spending by adding expenses',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showChartsDialog(
    BuildContext context,
    Map<String, double> categoryExpenses,
    double total,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Expense Charts'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: categoryExpenses.isEmpty
              ? const Center(child: Text('No data to display'))
              : PieChart(
                  PieChartData(
                    sections: _buildPieChartSections(categoryExpenses, total),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
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
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categoryExpenses,
    double total,
  ) {
    return categoryExpenses.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        color: AppTheme.getCategoryColor(entry.key),
        radius: 60,
      );
    }).toList();
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.filePdf),
              title: const Text('Export as PDF'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('PDF export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.fileCsv),
              title: const Text('Export as CSV'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV export coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const FaIcon(FontAwesomeIcons.share),
              title: const Text('Share Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
