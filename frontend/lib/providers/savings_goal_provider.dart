import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import '../services/api_service.dart';

class SavingsGoalProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<SavingsGoal> _savingsGoals = [];
  bool _isLoading = false;
  String? _error;

  List<SavingsGoal> get savingsGoals => _savingsGoals;
  List<SavingsGoal> get goals => _savingsGoals; // Backward compatibility
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getSavingsGoals();
      _savingsGoals = data.map((s) => SavingsGoal.fromJson(s)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading savings goals: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  Future<void> addSavingsGoal(SavingsGoal goal) async {
    try {
      final response = await _api.createSavingsGoal(goal.toJson());
      final newGoal = SavingsGoal.fromJson(response);
      _savingsGoals.add(newGoal);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding savings goal: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> addGoal(SavingsGoal goal) async => addSavingsGoal(goal);

  Future<void> updateSavingsGoal(SavingsGoal goal) async {
    try {
      final response = await _api.updateSavingsGoal(goal.id!, goal.toJson());
      final updatedGoal = SavingsGoal.fromJson(response);
      final index = _savingsGoals.indexWhere((s) => s.id == goal.id);
      if (index != -1) {
        _savingsGoals[index] = updatedGoal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating savings goal: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> updateGoal(SavingsGoal goal) async => updateSavingsGoal(goal);

  Future<void> deleteSavingsGoal(String id) async {
    try {
      await _api.deleteSavingsGoal(id);
      _savingsGoals.removeWhere((s) => s.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting savings goal: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> deleteGoal(String id) async => deleteSavingsGoal(id);

  Future<void> addContribution(String id, double amount) async {
    try {
      final response = await _api.contributeSavings(id, amount);
      final updatedGoal = SavingsGoal.fromJson(response);
      final index = _savingsGoals.indexWhere((s) => s.id == id);
      if (index != -1) {
        _savingsGoals[index] = updatedGoal;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error adding contribution: $e');
      rethrow;
    }
  }

  // Backward compatibility alias
  Future<void> addToGoal(String id, double amount) async =>
      addContribution(id, amount);

  List<SavingsGoal> get activeGoals =>
      _savingsGoals.where((s) => !s.isCompleted).toList();
  List<SavingsGoal> get completedGoals =>
      _savingsGoals.where((s) => s.isCompleted).toList();

  // Backward compatibility aliases
  List<SavingsGoal> getActiveGoals() => activeGoals;
  List<SavingsGoal> getCompletedGoals() => completedGoals;

  double get totalTargetAmount =>
      _savingsGoals.fold(0, (sum, s) => sum + s.targetAmount);
  double get totalCurrentAmount =>
      _savingsGoals.fold(0, (sum, s) => sum + s.currentAmount);
  double get overallProgress => totalTargetAmount > 0
      ? (totalCurrentAmount / totalTargetAmount) * 100
      : 0;

  // Backward compatibility aliases
  double getTotalSavingsTarget() => totalTargetAmount;
  double getTotalSavingsCurrent() => totalCurrentAmount;
  double getSavingsProgress() => overallProgress;

  List<SavingsGoal> getGoalsByCategory(String category) {
    return _savingsGoals.where((s) => s.category == category).toList();
  }

  List<SavingsGoal> getGoalsByPriority(String priority) {
    return _savingsGoals.where((s) => s.priority == priority).toList();
  }
}
