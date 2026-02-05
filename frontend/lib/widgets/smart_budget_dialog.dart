import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/budget.dart';
import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';

class SmartBudgetDialog extends StatefulWidget {
  const SmartBudgetDialog({super.key});

  @override
  State<SmartBudgetDialog> createState() => _SmartBudgetDialogState();
}

class _SmartBudgetDialogState extends State<SmartBudgetDialog> {
  String _strategy = 'Balanced';
  double _income = 0;

  final Map<String, Map<String, double>> _strategies = {
    'Balanced': {
      'Food & Dining': 0.15,
      'Groceries': 0.05,
      'Transportation': 0.10,
      'Utilities': 0.08,
      'Mobile Recharge': 0.02,
      'DTH': 0.01,
      'Health & Fitness': 0.10,
      'Education': 0.10,
      'Entertainment': 0.08,
      'Shopping': 0.06,
      'Personal Care': 0.05,
      'Family': 0.10,
      'Kids': 0.05,
      'Pets': 0.03,
      'Others': 0.02,
    },
    'Conservative': {
      'Food & Dining': 0.12,
      'Groceries': 0.06,
      'Transportation': 0.08,
      'Utilities': 0.10,
      'Mobile Recharge': 0.02,
      'DTH': 0.01,
      'Health & Fitness': 0.12,
      'Education': 0.12,
      'Entertainment': 0.05,
      'Shopping': 0.04,
      'Personal Care': 0.04,
      'Family': 0.12,
      'Kids': 0.06,
      'Pets': 0.03,
      'Others': 0.03,
    },
    'Aggressive': {
      'Food & Dining': 0.18,
      'Groceries': 0.04,
      'Transportation': 0.12,
      'Utilities': 0.08,
      'Mobile Recharge': 0.02,
      'DTH': 0.01,
      'Health & Fitness': 0.08,
      'Education': 0.08,
      'Entertainment': 0.10,
      'Shopping': 0.08,
      'Personal Care': 0.06,
      'Family': 0.08,
      'Kids': 0.03,
      'Pets': 0.01,
      'Others': 0.01,
    },
  };

  @override
  void initState() {
    super.initState();
    // Get total income
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );
      setState(() {
        _income = financialManager.getMonthlyIncome();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardColor = Theme.of(context).cardColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FaIcon(
                    FontAwesomeIcons.robot,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Budget',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'AI-powered allocation',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Income Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    'Monthly Income',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${NumberFormat('#,##,##0').format(_income)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Strategy Selector
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Strategy',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _strategy,
                      isExpanded: true,
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: textSecondary,
                      ),
                      dropdownColor: cardColor,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                      items: _strategies.keys.map((strategy) {
                        return DropdownMenuItem(
                          value: strategy,
                          child: Row(
                            children: [
                              Icon(
                                _getStrategyIcon(strategy),
                                size: 16,
                                color: _getStrategyColor(strategy),
                              ),
                              const SizedBox(width: 8),
                              Text(strategy),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _strategy = value);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Allocation List
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Proposed Allocation',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _strategies[_strategy]!.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.grey.withValues(alpha: 0.1)),
                      itemBuilder: (context, index) {
                        final entry = _strategies[_strategy]!.entries
                            .toList()[index];
                        final amount = _income * entry.value;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.getCategoryColor(
                                    entry.key,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: FaIcon(
                                  AppTheme.getCategoryIcon(entry.key),
                                  size: 14,
                                  color: AppTheme.getCategoryColor(entry.key),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: textPrimary,
                                  ),
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₹${NumberFormat('#,##,##0').format(amount)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '${(entry.value * 100).round()}%',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: textSecondary,
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
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _income > 0 ? _applyBudgets : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Apply Plan',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStrategyIcon(String strategy) {
    switch (strategy) {
      case 'Balanced':
        return Icons.balance;
      case 'Conservative':
        return Icons.savings_outlined;
      case 'Aggressive':
        return Icons.trending_up;
      default:
        return Icons.pie_chart;
    }
  }

  Color _getStrategyColor(String strategy) {
    switch (strategy) {
      case 'Balanced':
        return AppTheme.primaryColor;
      case 'Conservative':
        return AppTheme.successColor;
      case 'Aggressive':
        return AppTheme.errorColor;
      default:
        return Colors.grey;
    }
  }

  void _applyBudgets() {
    final manager = Provider.of<FinancialDataManager>(context, listen: false);
    final allocations = _strategies[_strategy]!;
    final now = DateTime.now();

    for (var entry in allocations.entries) {
      final amount = _income * entry.value;
      if (amount > 0) {
        // Check if budget exists for this category and month
        final existing = manager.budgets
            .where(
              (b) =>
                  b.category == entry.key &&
                  b.month == now.month &&
                  b.year == now.year,
            )
            .toList();

        if (existing.isNotEmpty) {
          // Update existing
          final updated = existing.first.copyWith(allocatedAmount: amount);
          manager.updateBudget(updated);
        } else {
          // Create new
          final budget = Budget(
            id: null, // Don't generate UUID - let MongoDB create the _id
            category: entry.key,
            allocatedAmount: amount,
            month: now.month,
            year: now.year,
          );
          manager.addBudget(budget);
        }
      }
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Smart budgets applied successfully!',
          style: GoogleFonts.inter(),
        ),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
