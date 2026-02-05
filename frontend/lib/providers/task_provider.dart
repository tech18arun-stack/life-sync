import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/supabase_service.dart';
import '../services/notification_service.dart';

class TaskProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  final _notificationService = NotificationService();

  List<Task> _tasks = [];
  bool _isLoading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _supabase.getTasks(); // Add userId filter if needed
      _tasks = data.map((t) => Task.fromJson(t)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading tasks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  Future<void> addTask(Task task) async {
    try {
      final response = await _supabase.createTask(task.toJson());
      final newTask = Task.fromJson(response);
      _tasks.add(newTask);

      // Schedule notification for the new task
      _notificationService.scheduleTaskNotification(newTask);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding task: $e');
      rethrow;
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      final response = await _supabase.updateTask(task.id!, task.toJson());
      final updatedTask = Task.fromJson(response);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;

        // Cancel old notifications and schedule new ones
        _notificationService.cancelTaskNotifications(task.id!);
        _notificationService.scheduleTaskNotification(updatedTask);

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
      _tasks.removeWhere((t) => t.id == id);

      // Cancel notifications for deleted task
      _notificationService.cancelTaskNotifications(id);

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting task: $e');
      rethrow;
    }
  }

  Future<void> toggleTaskCompletion(String id) async {
    try {
      final task = _tasks.firstWhere((t) => t.id == id);

      if (!task.isCompleted) {
        // Mark as complete - update the task status
        task.isCompleted = true;
        task.status = 'Completed';
        await updateTask(task);
        _notificationService.cancelTaskNotifications(id);
      } else {
        // Toggle back to incomplete
        task.isCompleted = false;
        task.status = 'Pending';
        await updateTask(task);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error toggling task completion: $e');
      rethrow;
    }
  }

  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();
  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();

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

  void notifyOverdueTasks() {
    final overdueTasks = getOverdueTasks();
    for (var task in overdueTasks) {
      _notificationService.showTaskOverdueNotification(task);
    }
  }
}
