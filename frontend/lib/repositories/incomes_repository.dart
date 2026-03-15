import '../models/income.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

/// Incomes Repository - Handles all income-related data operations
class IncomesRepository implements BaseRepository<Income> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<Income> create(Income item) async {
    final data = await _appwrite.createIncome(item.toJson());
    return Income.fromJson(data);
  }

  @override
  Future<List<Income>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getIncomes(
      source: filters?['source'] as String?,
    );
    return data.map((json) => Income.fromJson(json)).toList();
  }

  @override
  Future<Income?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.incomesCollection,
      documentId: id,
    );
    if (data == null) return null;
    return Income.fromJson(data);
  }

  @override
  Future<Income> update(String id, Income item) async {
    final data = await _appwrite.updateIncome(id, item.toJson());
    return Income.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteIncome(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get incomes by source
  Future<List<Income>> getBySource(String source) async {
    final data = await _appwrite.getIncomes(source: source);
    return data.map((json) => Income.fromJson(json)).toList();
  }

  /// Get incomes for a specific month and year
  Future<List<Income>> getByMonth(int month, int year) async {
    final allIncomes = await getAll();
    return allIncomes.where((income) {
      return income.date.month == month && income.date.year == year;
    }).toList();
  }

  /// Get total income for a month
  Future<double> getTotalByMonth(int month, int year) async {
    final incomes = await getByMonth(month, year);
    return incomes.fold<double>(0.0, (double sum, Income income) => sum + income.amount);
  }

  /// Get total income by source
  Future<Map<String, double>> getIncomesBySource() async {
    final incomes = await getAll();
    final Map<String, double> sourceTotals = {};

    for (final income in incomes) {
      sourceTotals[income.source] = (sourceTotals[income.source] ?? 0) + income.amount;
    }

    return sourceTotals;
  }

  /// Get recurring incomes
  Future<List<Income>> getRecurringIncomes() async {
    final allIncomes = await getAll();
    return allIncomes.where((income) => income.isRecurring).toList();
  }
}
