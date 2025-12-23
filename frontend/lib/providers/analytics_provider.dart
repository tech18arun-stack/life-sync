import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import 'financial_data_manager.dart';

class AnalyticsProvider extends ChangeNotifier {
  FinancialDataManager? _financialManager;

  // Cache for calculations
  final Map<String, double> _categoryTotals = {};
  List<Map<String, dynamic>> _dailySpending = [];
  Map<String, dynamic> _predictions = {};

  void setFinancialManager(FinancialDataManager manager) {
    _financialManager = manager;
    _recalculateAnalytics();
    notifyListeners();
  }

  void _recalculateAnalytics() {
    if (_financialManager == null) return;

    final expenses = _financialManager!.expenses;
    if (expenses.isEmpty) return;

    _calculateCategoryTotals(expenses);
    _calculateDailySpending(expenses);
    _generatePredictions(expenses);
  }

  void _calculateCategoryTotals(List<Expense> expenses) {
    _categoryTotals.clear();
    for (var expense in expenses) {
      _categoryTotals[expense.category] =
          (_categoryTotals[expense.category] ?? 0) + expense.amount;
    }
  }

  void _calculateDailySpending(List<Expense> expenses) {
    _dailySpending.clear();
    // Group by date
    final grouped = <String, double>{};
    for (var expense in expenses) {
      final dateKey = DateFormat('yyyy-MM-dd').format(expense.date);
      grouped[dateKey] = (grouped[dateKey] ?? 0) + expense.amount;
    }

    // Convert to list and sort
    _dailySpending =
        grouped.entries.map((e) {
          return {'date': DateTime.parse(e.key), 'amount': e.value};
        }).toList()..sort(
          (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
        );
  }

  void _generatePredictions(List<Expense> expenses) {
    // Simple moving average prediction for current month
    final now = DateTime.now();
    final currentMonthExpenses = expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amount);

    // Calculate average of last 3 months
    double totalLast3Months = 0;
    int monthsCount = 0;

    for (int i = 1; i <= 3; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthlyTotal = expenses
          .where(
            (e) =>
                e.date.year == monthDate.year &&
                e.date.month == monthDate.month,
          )
          .fold<double>(0, (sum, e) => sum + e.amount);

      if (monthlyTotal > 0) {
        totalLast3Months += monthlyTotal;
        monthsCount++;
      }
    }

    final averageMonthly = monthsCount > 0
        ? totalLast3Months / monthsCount
        : currentMonthExpenses;

    // Simple projection: (current / days_passed) * total_days
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final projection = now.day > 0
        ? (currentMonthExpenses / now.day) * daysInMonth
        : averageMonthly;

    _predictions = {
      'currentMonth': currentMonthExpenses,
      'average': averageMonthly,
      'projected': projection,
      'status': projection > averageMonthly ? 'Over Average' : 'On Track',
    };
  }

  // Public Getters
  Map<String, double> get categoryTotals => _categoryTotals;
  List<Map<String, dynamic>> get dailySpending => _dailySpending;
  Map<String, dynamic> get predictions => _predictions;

  List<Map<String, dynamic>> getTrendData({int days = 30}) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _dailySpending
        .where((e) => (e['date'] as DateTime).isAfter(cutoff))
        .toList();
  }

  Map<String, double> getTopCategories({int limit = 5}) {
    final sorted = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <String, double>{};
    for (var i = 0; i < sorted.length && i < limit; i++) {
      result[sorted[i].key] = sorted[i].value;
    }
    return result;
  }

  Map<String, dynamic> compareMonthToPrevious() {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final prevMonth = DateTime(now.year, now.month - 1);

    final expenses = _financialManager?.expenses ?? [];

    final currentTotal = expenses
        .where(
          (e) =>
              e.date.year == currentMonth.year &&
              e.date.month == currentMonth.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final prevTotal = expenses
        .where(
          (e) =>
              e.date.year == prevMonth.year && e.date.month == prevMonth.month,
        )
        .fold<double>(0, (sum, e) => sum + e.amount);

    final diff = currentTotal - prevTotal;
    final percent = prevTotal > 0 ? (diff / prevTotal * 100) : 0.0;

    return {
      'current': currentTotal,
      'previous': prevTotal,
      'difference': diff,
      'percentChange': percent,
    };
  }
}
