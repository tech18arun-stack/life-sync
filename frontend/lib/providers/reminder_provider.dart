import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../models/expense.dart';
import 'financial_data_manager.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class ReminderProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<Reminder> _reminders = [];
  bool _isLoading = false;
  String? _error;
  FinancialDataManager? _financialManager;

  void setFinancialManager(FinancialDataManager manager) {
    _financialManager = manager;
  }

  List<Reminder> get reminders => _reminders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getReminders();
      _reminders = data.map((r) => Reminder.fromJson(r)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading reminders: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addReminder(Reminder reminder) async {
    try {
      final response = await _api.createReminder(reminder.toJson());
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
      final response = await _api.updateReminder(
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
      await _api.deleteReminder(id);
      NotificationService().cancelNotification(id.hashCode);
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting reminder: $e');
      rethrow;
    }
  }

  Future<void> markAsPaid(String id) async {
    try {
      final response = await _api.markReminderPaid(id);
      final updatedReminder = Reminder.fromJson(response);
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index != -1) {
        _reminders[index] = updatedReminder;
        notifyListeners();
      }

      // Create expense automatically using FinancialDataManager
      if (updatedReminder.amount != null && _financialManager != null) {
        final expense = Expense(
          description: updatedReminder.title,
          amount: updatedReminder.amount!,
          date: DateTime.now(),
          category: _mapReminderTypeToCategory(updatedReminder.type),
          notes: 'Paid from reminder: ${updatedReminder.description ?? ""}',
        );
        await _financialManager!.addExpense(expense);
      }
    } catch (e) {
      debugPrint('Error marking reminder as paid: $e');
      rethrow;
    }
  }

  String _mapReminderTypeToCategory(String type) {
    switch (type.toLowerCase()) {
      case 'bill':
      case 'recharge':
        return 'Bills';
      case 'emi':
      case 'loan':
        return 'Other';
      case 'subscription':
        return 'Entertainment';
      default:
        return 'Other';
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
}
