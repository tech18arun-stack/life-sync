import '../models/expense.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

/// Expenses Repository - Handles all expense-related data operations
class ExpensesRepository implements BaseRepository<Expense> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<Expense> create(Expense item) async {
    final data = await _appwrite.createExpense(item.toJson());
    return Expense.fromJson(data);
  }

  @override
  Future<List<Expense>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getExpenses(
      category: filters?['category'] as String?,
    );
    return data.map((json) => Expense.fromJson(json)).toList();
  }

  @override
  Future<Expense?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.expensesCollection,
      documentId: id,
    );
    if (data == null) return null;
    return Expense.fromJson(data);
  }

  @override
  Future<Expense> update(String id, Expense item) async {
    final data = await _appwrite.updateExpense(id, item.toJson());
    return Expense.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteExpense(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get expenses by category
  Future<List<Expense>> getByCategory(String category) async {
    final data = await _appwrite.getExpenses(category: category);
    return data.map((json) => Expense.fromJson(json)).toList();
  }

  /// Get expenses for a specific month and year
  Future<List<Expense>> getByMonth(int month, int year) async {
    final allExpenses = await getAll();
    return allExpenses.where((expense) {
      return expense.date.month == month && expense.date.year == year;
    }).toList();
  }

  /// Get total expenses for a category
  Future<double> getTotalByCategory(String category) async {
    final expenses = await getByCategory(category);
    return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  /// Get total expenses for a month
  Future<double> getTotalByMonth(int month, int year) async {
    final expenses = await getByMonth(month, year);
    return expenses.fold<double>(0.0, (double sum, Expense expense) => sum + expense.amount);
  }

  /// Get expenses grouped by category
  Future<Map<String, double>> getExpensesByCategory() async {
    final expenses = await getAll();
    final Map<String, double> categoryTotals = {};

    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    return categoryTotals;
  }
}
