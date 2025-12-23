import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/budget.dart';
import '../providers/financial_data_manager.dart';

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
      'Food': 0.20,
      'Transport': 0.10,
      'Utilities': 0.10,
      'Health': 0.10,
      'Education': 0.10,
      'Entertainment': 0.10,
      'Shopping': 0.10,
      'Others': 0.20,
    },
    'Conservative': {
      'Food': 0.15,
      'Transport': 0.05,
      'Utilities': 0.10,
      'Health': 0.15,
      'Education': 0.15,
      'Entertainment': 0.05,
      'Shopping': 0.05,
      'Others': 0.30,
    },
    'Aggressive': {
      'Food': 0.25,
      'Transport': 0.15,
      'Utilities': 0.10,
      'Health': 0.05,
      'Education': 0.05,
      'Entertainment': 0.20,
      'Shopping': 0.15,
      'Others': 0.05,
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
        _income = financialManager.getTotalIncome();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Smart Budget Planner',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Based on your total income: ₹${_income.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),

            // Strategy Selection
            DropdownButtonFormField<String>(
              initialValue: _strategy,
              decoration: const InputDecoration(
                labelText: 'Strategy',
                prefixIcon: Icon(Icons.psychology),
              ),
              items: _strategies.keys.map((strategy) {
                return DropdownMenuItem(value: strategy, child: Text(strategy));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _strategy = value);
                }
              },
            ),
            const SizedBox(height: 20),

            // Preview
            Text(
              'Proposed Allocation:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ..._strategies[_strategy]!.entries.map((entry) {
              final amount = _income * entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Text(
                      '₹${amount.toStringAsFixed(0)} (${(entry.value * 100).round()}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _income > 0 ? _applyBudgets : null,
                  child: const Text('Apply Budgets'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
            .firstOrNull;

        if (existing != null) {
          // Update existing
          final updated = existing.copyWith(allocatedAmount: amount);
          manager.updateBudget(updated);
        } else {
          // Create new
          final budget = Budget(
            id: const Uuid().v4(),
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
      const SnackBar(content: Text('Smart budgets applied successfully!')),
    );
  }
}
