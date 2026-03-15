import 'package:flutter/foundation.dart';
import '../models/savings_goal.dart';
import '../repositories/all_repositories.dart';

/// Savings Goal Provider - State management for savings goals
/// 
/// Updated to use Appwrite backend via SavingsGoalsRepository.
class SavingsGoalProvider with ChangeNotifier {
  final SavingsGoalsRepository _repository = SavingsGoalsRepository();

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
      _savingsGoals = await _repository.getAll();
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
      final newGoal = await _repository.create(goal);
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
      final updatedGoal = await _repository.update(goal.id!, goal);
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
      await _repository.delete(id);
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
      final goal = _savingsGoals.firstWhere((s) => s.id == id);
      goal.currentAmount += amount;

      // Update the goal in the database
      final updatedGoal = await _repository.update(id, goal);

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
