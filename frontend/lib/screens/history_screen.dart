import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../providers/reminder_provider.dart';
import '../utils/app_theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filter = 'All'; // All, Expenses, Income, Reminders
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Data Aggregation
    final financialManager = Provider.of<FinancialDataManager>(context);
    final reminderProvider = Provider.of<ReminderProvider>(context);

    List<HistoryItem> items = _aggregateData(
      financialManager,
      reminderProvider,
    );

    // Sort and Filter
    items.sort((a, b) => b.date.compareTo(a.date));
    final filteredItems = _filterItems(items);

    // Calculations for Summary
    final double totalIncome = filteredItems
        .where((i) => i.amount > 0 && i.type == 'Income')
        .fold(0, (sum, item) => sum + item.amount);
    final double totalExpense = filteredItems
        .where(
          (i) => i.amount < 0 || (i.type == 'Reminder' && i.amount > 0),
        ) // Reminders are usually expenses to be paid
        .fold(0, (sum, item) => sum + item.amount.abs());

    // Grouping
    final groupedItems = _groupItems(filteredItems);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                children: [
                  _buildSummaryCard(totalIncome, totalExpense),
                  const SizedBox(height: 20),
                  _buildFilterRow(),
                  const SizedBox(height: 20),
                  if (filteredItems.isEmpty) _buildEmptyState(),
                ],
              ),
            ),
          ),
          if (filteredItems.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.only(bottom: 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final monthYear = groupedItems.keys.elementAt(index);
                  final monthItems = groupedItems[monthYear]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        child: Text(
                          monthYear.toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      ...monthItems.map((item) => _buildTransactionItem(item)),
                      const SizedBox(height: 16),
                    ],
                  );
                }, childCount: groupedItems.keys.length),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DATA HELPERS
  // ---------------------------------------------------------------------------

  List<HistoryItem> _aggregateData(
    FinancialDataManager fm,
    ReminderProvider rp,
  ) {
    List<HistoryItem> list = [];

    // Expenses
    for (var e in fm.expenses) {
      list.add(
        HistoryItem(
          id: e.id ?? '',
          title: e.contactName ?? e.category,
          subtitle: e.description.isNotEmpty ? e.description : 'Expense',
          amount: -e.amount, // Negative for expense
          date: e.date,
          type: 'Expense',
          icon: AppTheme.getCategoryIcon(e.category),
          color: AppTheme.getCategoryColor(e.category),
          phoneNumber: e.phoneNumber,
          category: e.category,
        ),
      );
    }

    // Income
    for (var i in fm.incomes) {
      list.add(
        HistoryItem(
          id: i.id ?? '',
          title: i.contactName ?? 'Income',
          subtitle: i.description.isNotEmpty ? i.description : 'Salary/Deposit',
          amount: i.amount,
          date: i.date,
          type: 'Income',
          icon: FontAwesomeIcons.wallet,
          color: const Color(0xFF2ECC71),
          phoneNumber: i.phoneNumber,
          category: 'Income',
        ),
      );
    }

    // Reminders
    for (var r in rp.reminders) {
      list.add(
        HistoryItem(
          id: r.id ?? '',
          title: r.contactName ?? r.title,
          subtitle: 'Reminder: ${r.title}',
          amount:
              r.amount ??
              0, // Reminders are shown as positive but treated as potential cost
          date: r.dueDate,
          type: 'Reminder',
          status: r.isPaid ? 'Paid' : 'Pending',
          icon: r.isPaid ? FontAwesomeIcons.check : FontAwesomeIcons.bell,
          color: r.isPaid ? const Color(0xFF4AC3B2) : const Color(0xFFF39C12),
          phoneNumber: r.phoneNumber,
          category: 'Reminder',
        ),
      );
    }
    return list;
  }

  List<HistoryItem> _filterItems(List<HistoryItem> items) {
    return items.where((item) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch =
          item.title.toLowerCase().contains(q) ||
          (item.phoneNumber?.contains(q) ?? false) ||
          item.subtitle.toLowerCase().contains(q) ||
          item.type.toLowerCase().contains(q);

      bool matchesFilter = true;
      if (_filter == 'Expenses') matchesFilter = item.type == 'Expense';
      if (_filter == 'Income') matchesFilter = item.type == 'Income';
      if (_filter == 'Reminders') matchesFilter = item.type == 'Reminder';

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Map<String, List<HistoryItem>> _groupItems(List<HistoryItem> items) {
    Map<String, List<HistoryItem>> grouped = {};
    for (var item in items) {
      String key = DateFormat('MMMM yyyy').format(item.date);
      if (!grouped.containsKey(key)) grouped[key] = [];
      grouped[key]!.add(item);
    }
    return grouped;
  }

  // ---------------------------------------------------------------------------
  // UI COMPONENTS
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      expandedHeight: 140.0,
      pinned: true,
      floating: true,
      elevation: 0,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
        title: SizedBox(
          height: 40,
          child: TextField(
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.inter(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search records...',
              hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey),
              prefixIcon: const Icon(Icons.search, size: 18),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
        background: Container(
          alignment: Alignment.topCenter,
          padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
          child: Row(
            children: [
              Text(
                'History',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward,
                        size: 12,
                        color: Color(0xFF2ECC71),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Total Income',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '₹${NumberFormat('#,##0').format(income)}',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward,
                          size: 12,
                          color: Color(0xFFFF5252),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Total Spent',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${NumberFormat('#,##0').format(expense)}',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All'),
          _buildFilterChip('Expenses'),
          _buildFilterChip('Income'),
          _buildFilterChip('Reminders'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final selected = _filter == label;
    return GestureDetector(
      onTap: () => setState(() => _filter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? AppTheme.primaryColor
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(HistoryItem item) {
    final bool isExpense = item.type == 'Expense';
    final bool isReminder = item.type == 'Reminder';

    Color amountColor;
    if (isExpense) {
      amountColor = const Color(0xFFFF5252);
    } else if (item.amount > 0) {
      amountColor = const Color(0xFF2ECC71);
    } else {
      amountColor =
          Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    }

    // Use warning yellow for pending reminders
    if (isReminder && item.status == 'Pending') {
      amountColor = const Color(0xFFF39C12);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Details view could go here
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: FaIcon(item.icon, color: item.color, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Theme.of(context).textTheme.bodyLarge?.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                      if (item.phoneNumber != null)
                        Text(
                          item.phoneNumber!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.amount < 0 ? "-" : (isExpense ? "-" : "+")}₹${NumberFormat('#,##,##0').format(item.amount.abs())}',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d').format(item.date),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'No records found',
              style: GoogleFonts.inter(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class HistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String type;
  final String? status;
  final IconData icon;
  final Color color;
  final String? phoneNumber;
  final String category;

  HistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.type,
    this.status,
    required this.icon,
    required this.color,
    this.phoneNumber,
    required this.category,
  });
}
