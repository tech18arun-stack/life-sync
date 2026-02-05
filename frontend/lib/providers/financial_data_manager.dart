import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../models/budget.dart';
import '../models/reminder.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

/// Centralized Financial Data Manager
/// Manages all financial data (income, expenses, budgets, reminders, tasks) via Supabase
class FinancialDataManager with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();

  // Lists
  List<Expense> _expenses = [];
  List<Income> _incomes = [];
  List<Budget> _budgets = [];
  List<Reminder> _reminders = [];
  List<Task> _tasks = [];

  // Loading states
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Expense> get expenses => _expenses;
  List<Income> get incomes => _incomes;
  List<Budget> get budgets => _budgets;
  List<Reminder> get reminders => _reminders;
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Initialization - Load data from Supabase
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadExpenses(),
        _loadIncomes(),
        _loadBudgets(),
        _loadReminders(),
        _loadTasks(),
      ]);
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
      final data = await _supabase.getExpenses(); // Add userId filter if needed
      _expenses = data.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading expenses: $e');
    }
  }

  Future<void> _loadIncomes() async {
    try {
      final data = await _supabase.getIncomes(); // Add userId filter if needed
      _incomes = data.map((i) => Income.fromJson(i)).toList();
    } catch (e) {
      debugPrint('Error loading incomes: $e');
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final data = await _supabase.getBudgets(); // Add userId filter if needed
      _budgets = data.map((b) => Budget.fromJson(b)).toList();
    } catch (e) {
      debugPrint('Error loading budgets: $e');
    }
  }

  Future<void> _loadReminders() async {
    try {
      final data = await _supabase.getReminders(); // Add userId filter if needed
      _reminders = data.map((r) => Reminder.fromJson(r)).toList();
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  Future<void> _loadTasks() async {
    try {
      final data = await _supabase.getTasks(); // Add userId filter if needed
      _tasks = data.map((t) => Task.fromJson(t)).toList();
    } catch (e) {
      debugPrint('Error loading tasks: $e');
    }
  }

  // ======================== INCOME OPERATIONS ========================

  Future<void> addIncome(Income income) async {
    try {
      final response = await _supabase.createIncome(income.toJson());
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
      final response = await _supabase.updateIncome(income.id!, income.toJson());
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
      await _supabase.deleteIncome(id);
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
      final response = await _supabase.createExpense(expense.toJson());
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

      final response = await _supabase.updateExpense(expense.id!, expense.toJson());
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

      await _supabase.deleteExpense(id);
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

  // ======================== REMINDER OPERATIONS ========================

  Future<void> addReminder(Reminder reminder) async {
    try {
      final response = await _supabase.createReminder(reminder.toJson());
      final newReminder = Reminder.fromJson(response);
      _reminders.add(newReminder);
      NotificationService().scheduleReminderNotification(newReminder);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(Reminder reminder) async {
    try {
      final response = await _supabase.updateReminder(
        reminder.id!,
        reminder.toJson(),
      );
      final updatedReminder = Reminder.fromJson(response);
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = updatedReminder;
        NotificationService().scheduleReminderNotification(updatedReminder);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String id) async {
    try {
      await _supabase.deleteReminder(id);
      NotificationService().cancelNotification(id.hashCode);
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      rethrow;
    }
  }

  List<Reminder> getPendingReminders() {
    return _reminders.where((r) => !r.isPaid).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  List<Reminder> getOverdueReminders() {
    return _reminders.where((r) => r.isOverdue).toList();
  }

  List<Reminder> getDueSoonReminders() {
    return _reminders.where((r) => r.isDueSoon).toList();
  }

  List<Reminder> getRemindersByType(String type) {
    return _reminders.where((r) => r.type == type).toList();
  }

  List<Reminder> getUpcomingReminders({int days = 30}) {
    final endDate = DateTime.now().add(Duration(days: days));
    return _reminders
        .where(
          (r) =>
              !r.isPaid &&
              r.dueDate.isAfter(DateTime.now()) &&
              r.dueDate.isBefore(endDate),
        )
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  }

  double getTotalPendingAmount() {
    return _reminders
        .where((r) => !r.isPaid && r.amount != null)
        .fold(0, (sum, reminder) => sum + (reminder.amount ?? 0));
  }

  Map<String, int> getReminderCountByType() {
    Map<String, int> counts = {};
    for (var reminder in getPendingReminders()) {
      counts[reminder.type] = (counts[reminder.type] ?? 0) + 1;
    }
    return counts;
  }

  // ======================== TASK OPERATIONS ========================

  Future<void> addTask(Task task) async {
    try {
      final response = await _supabase.createTask(task.toJson());
      final newTask = Task.fromJson(response);
      _tasks.add(newTask);
      NotificationService().scheduleTaskNotification(newTask);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final response = await _supabase.updateTask(
        task.id!,
        task.toJson(),
      );
      final updatedTask = Task.fromJson(response);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        NotificationService().cancelTaskNotifications(task.id!);
        NotificationService().scheduleTaskNotification(updatedTask);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _supabase.deleteTask(id);
      NotificationService().cancelTaskNotifications(id);
      _tasks.removeWhere((t) => t.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  List<Task> getPendingTasks() {
    return _tasks.where((t) => !t.isCompleted).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((t) => t.isCompleted).toList();
  }

  List<Task> getTasksByCategory(String category) {
    return _tasks.where((t) => t.category == category).toList();
  }

  List<Task> getTasksByPriority(String priority) {
    return _tasks.where((t) => t.priority == priority).toList();
  }

  List<Task> getOverdueTasks() {
    final now = DateTime.now();
    return _tasks.where((t) {
      return !t.isCompleted && t.dueDate != null && t.dueDate!.isBefore(now);
    }).toList();
  }

  List<Task> getTodayTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _tasks.where((t) {
      return t.dueDate != null &&
          t.dueDate!.isAfter(today.subtract(const Duration(seconds: 1))) &&
          t.dueDate!.isBefore(tomorrow);
    }).toList();
  }

  // ======================== BUDGET OPERATIONS ========================

  Future<void> addBudget(Budget budget) async {
    try {
      final response = await _supabase.createBudget(budget.toJson());
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
      final response = await _supabase.updateBudget(budget.id!, budget.toJson());
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
      await _supabase.deleteBudget(id);
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
        // Update the spent amount in the budget object
        budget.spentAmount += amount;

        // Update the budget in the database
        final updatedBudgetData = budget.toJson();
        await _supabase.updateBudget(budget.id!, updatedBudgetData);

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
