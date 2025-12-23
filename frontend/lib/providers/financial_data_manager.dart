import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/budget.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

/// Centralized Financial Data Manager
/// Manages all financial data (income, expenses, budgets) via MongoDB API
class FinancialDataManager with ChangeNotifier {
  final ApiService _api = ApiService();

  // Lists
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Budget> _budgets = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Expense> get expenses => _expenses;
  List<Income> get incomes => _incomes;
  List<Budget> get budgets => _budgets;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialization - Load data from API
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([_loadExpenses(), _loadIncomes(), _loadBudgets()]);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error initializing financial data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  // ======================== LOAD DATA ========================

  Future<void> _loadExpenses() async {
    try {
      final data = await _api.getExpenses();
      _expenses = data.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  Future<void> _loadIncomes() async {
    try {
      final data = await _api.getIncomes();
      _incomes = data.map((i) => Income.fromJson(i)).toList();
    } catch (e) {
      debugPrint('Error loading incomes: $e');
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final data = await _api.getBudgets();
      _budgets = data.map((b) => Budget.fromJson(b)).toList();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }
  }

  // ======================== INCOME OPERATIONS ========================

  Future<void> addIncome(Income income) async {
    try {
      final response = await _api.createIncome(income.toJson());
      final newIncome = Income.fromJson(response);
      _incomes.add(newIncome);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding income: $e');
      rethrow;
    }
  }

  Future<void> updateIncome(Income income) async {
    try {
      final response = await _api.updateIncome(income.id!, income.toJson());
      final updatedIncome = Income.fromJson(response);
      final index = _incomes.indexWhere((i) => i.id == income.id);
      if (index != -1) {
        _incomes[index] = updatedIncome;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating income: $e');
      rethrow;
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await _api.deleteIncome(id);
      _incomes.removeWhere((i) => i.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting income: $e');
      rethrow;
    }
  }

  double getTotalIncome() {
    return _incomes.fold(0, (sum, income) => sum + income.amount);
  }

  double getIncomeByPeriod(DateTime start, DateTime end) {
    return _incomes
        .where(
          (i) =>
              i.date.isAfter(start.subtract(const Duration(days: 1))) &&
              i.date.isBefore(end.add(const Duration(days: 1))),
        )
        .fold(0, (sum, income) => sum + income.amount);
  }

  double getMonthlyIncome() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getIncomeByPeriod(startOfMonth, endOfMonth);
  }

  double getIncomeForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    return getIncomeByPeriod(startOfMonth, endOfMonth);
  }

  double getIncomeForYear(int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    return getIncomeByPeriod(startOfYear, endOfYear);
  }

  Map<String, double> getIncomeBySource() {
    Map<String, double> sourceIncome = {};
    for (var income in _incomes) {
      sourceIncome[income.source] =
          (sourceIncome[income.source] ?? 0) + income.amount;
    }
    return sourceIncome;
  }

  // ======================== EXPENSE OPERATIONS ========================

  Future<void> addExpense(Expense expense) async {
    try {
      final response = await _api.createExpense(expense.toJson());
      final newExpense = Expense.fromJson(response);
      _expenses.add(newExpense);

      // Update budget spending
      await _updateBudgetSpending(expense.category, expense.amount);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding expense: $e');
      rethrow;
    }
  }

  Future<void> updateExpense(Expense expense) async {
    try {
      final oldExpense = _expenses.firstWhere((e) => e.id == expense.id);

      // Reverse old expense effect on budget
      await _updateBudgetSpending(oldExpense.category, -oldExpense.amount);

      final response = await _api.updateExpense(expense.id!, expense.toJson());
      final updatedExpense = Expense.fromJson(response);

      // Apply new expense effect on budget
      await _updateBudgetSpending(expense.category, expense.amount);

      final index = _expenses.indexWhere((e) => e.id == expense.id);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating expense: $e');
      rethrow;
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      final expense = _expenses.firstWhere((e) => e.id == id);

      // Reverse expense effect on budget
      await _updateBudgetSpending(expense.category, -expense.amount);

      await _api.deleteExpense(id);
      _expenses.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting expense: $e');
      rethrow;
    }
  }

  double getTotalExpenses() {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }

  double getExpensesByCategory(String category) {
    return _expenses
        .where((e) => e.category == category)
        .fold(0, (sum, expense) => sum + expense.amount);
  }

  List<Expense> getExpensesByDateRange(DateTime start, DateTime end) {
    return _expenses.where((e) {
      return e.date.isAfter(start.subtract(const Duration(days: 1))) &&
          e.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  double getExpensesForYear(int year) {
    final startOfYear = DateTime(year, 1, 1);
    final endOfYear = DateTime(year, 12, 31);
    return getExpensesByDateRange(
      startOfYear,
      endOfYear,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getCategoryWiseExpenses() {
    Map<String, double> categoryExpenses = {};
    for (var expense in _expenses) {
      categoryExpenses[expense.category] =
          (categoryExpenses[expense.category] ?? 0) + expense.amount;
    }
    return categoryExpenses;
  }

  List<Expense> getRecentExpenses({int limit = 10}) {
    final sorted = List<Expense>.from(_expenses);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }

  // ======================== BUDGET OPERATIONS ========================

  Future<void> addBudget(Budget budget) async {
    try {
      final response = await _api.createBudget(budget.toJson());
      final newBudget = Budget.fromJson(response);
      _budgets.add(newBudget);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding budget: $e');
      rethrow;
    }
  }

  Future<void> updateBudget(Budget budget) async {
    try {
      final response = await _api.updateBudget(budget.id!, budget.toJson());
      final updatedBudget = Budget.fromJson(response);
      final index = _budgets.indexWhere((b) => b.id == budget.id);
      if (index != -1) {
        _budgets[index] = updatedBudget;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating budget: $e');
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    try {
      await _api.deleteBudget(id);
      _budgets.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting budget: $e');
      rethrow;
    }
  }

  Budget? getBudgetForCategory(String category) {
    final now = DateTime.now();
    try {
      return _budgets.firstWhere(
        (b) =>
            b.category == category &&
            b.month == now.month &&
            b.year == now.year,
      );
    } catch (e) {
      return null;
    }
  }

  List<Budget> getActiveBudgets() {
    final now = DateTime.now();
    return _budgets
        .where((b) => b.month == now.month && b.year == now.year && b.isActive)
        .toList();
  }

  List<Budget> getOverBudgets() {
    return getActiveBudgets().where((b) => b.isOverBudget).toList();
  }

  List<Budget> getBudgetsNeedingAlert() {
    return getActiveBudgets().where((b) => b.shouldAlert).toList();
  }

  double getTotalBudgetedAmount() {
    return getActiveBudgets().fold(
      0,
      (sum, budget) => sum + budget.allocatedAmount,
    );
  }

  double getTotalSpentAmount() {
    return getActiveBudgets().fold(
      0,
      (sum, budget) => sum + budget.spentAmount,
    );
  }

  // ======================== PRIVATE HELPER METHODS ========================

  Future<void> _updateBudgetSpending(String category, double amount) async {
    final now = DateTime.now();
    try {
      final budget = _budgets.firstWhere(
        (b) =>
            b.category == category &&
            b.month == now.month &&
            b.year == now.year,
      );

      if (budget.id != null) {
        await _api.addBudgetSpending(budget.id!, amount);
        budget.spentAmount += amount;
        notifyListeners();

        if (budget.shouldAlert) {
          NotificationService().showBudgetAlert(
            budget.category,
            budget.percentageUsed,
          );
        }
      }
    } catch (e) {
      debugPrint('No active budget found for category: $category');
    }
  }

  // ======================== FINANCIAL ANALYTICS ========================

  double getNetBalance() => getTotalIncome() - getTotalExpenses();

  double getMonthlyNetBalance() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    final monthlyIncome = getIncomeByPeriod(startOfMonth, endOfMonth);
    final monthlyExpenses = getExpensesByDateRange(
      startOfMonth,
      endOfMonth,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
    return monthlyIncome - monthlyExpenses;
  }

  double getSavings() => getNetBalance();
  double getMonthlySavings() => getMonthlyNetBalance();

  double getSavingsPercentage() {
    final income = getTotalIncome();
    if (income == 0) return 0;
    return (getSavings() / income) * 100;
  }

  double getBudgetCompliancePercentage() {
    final activeBudgets = getActiveBudgets();
    if (activeBudgets.isEmpty) return 100;
    final compliantBudgets = activeBudgets.where((b) => !b.isOverBudget).length;
    return (compliantBudgets / activeBudgets.length) * 100;
  }

  double getFinancialHealthScore() {
    double score = 0;
    final savingsRate = getSavingsPercentage();
    score += (savingsRate > 20 ? 40 : savingsRate * 2);
    score += getBudgetCompliancePercentage() * 0.4;
    if (getMonthlyIncome() > 0) score += 20;
    return score.clamp(0, 100);
  }

  List<Map<String, dynamic>> getDailySpending({int days = 7}) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days - 1));
    Map<DateTime, double> dailyMap = {};

    for (int i = 0; i < days; i++) {
      final date = DateTime(startDate.year, startDate.month, startDate.day + i);
      dailyMap[date] = 0;
    }

    for (var expense in _expenses) {
      final expenseDate = DateTime(
        expense.date.year,
        expense.date.month,
        expense.date.day,
      );
      if (expenseDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          expenseDate.isBefore(now.add(const Duration(days: 1)))) {
        final key = dailyMap.keys.firstWhere(
          (k) =>
              k.year == expenseDate.year &&
              k.month == expenseDate.month &&
              k.day == expenseDate.day,
          orElse: () => expenseDate,
        );
        if (dailyMap.containsKey(key)) {
          dailyMap[key] = (dailyMap[key] ?? 0) + expense.amount;
        }
      }
    }

    return dailyMap.entries
        .map((e) => {'date': e.key, 'amount': e.value})
        .toList()
      ..sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );
  }

  // ======================== MONTHLY/YEARLY CALCULATIONS ========================

  double getAvailableBalance() => getTotalIncome() - getTotalExpenses();

  double getMonthlyAvailableBalance() =>
      getMonthlyIncome() - getMonthlyExpenses();

  double getMonthlyExpenses() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    return getExpensesByDateRange(
      startOfMonth,
      endOfMonth,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getExpensesForMonth(DateTime month) {
    final startOfMonth = DateTime(month.year, month.month, 1);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    return getExpensesByDateRange(
      startOfMonth,
      endOfMonth,
    ).fold(0.0, (sum, expense) => sum + expense.amount);
  }

  Map<String, double> getCashFlowSummary() {
    return {
      'totalIncome': getTotalIncome(),
      'totalExpenses': getTotalExpenses(),
      'availableBalance': getAvailableBalance(),
      'monthlyIncome': getMonthlyIncome(),
      'monthlyExpenses': getMonthlyExpenses(),
      'monthlyAvailable': getMonthlyAvailableBalance(),
      'savingsRate': getSavingsPercentage(),
    };
  }
}
