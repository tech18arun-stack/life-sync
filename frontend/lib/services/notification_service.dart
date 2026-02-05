import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reminder.dart';
import '../models/task.dart';
import '../models/savings_goal.dart';
import '../models/family_event.dart';
import '../models/health_record.dart';
import '../models/expense.dart';
import '../models/notification_item.dart';

/// Notification Service for LifeSync
/// Handles all local notifications triggered by app events and history tracking
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification Channels
  static const String _channelIdGeneral = 'lifesync_general';
  static const String _channelIdReminders = 'lifesync_reminders';
  static const String _channelIdTasks = 'lifesync_tasks';
  static const String _channelIdBudget = 'lifesync_budget';
  static const String _channelIdSavings = 'lifesync_savings';
  static const String _channelIdEvents = 'lifesync_events';
  static const String _channelIdHealth = 'lifesync_health';
  static const String _channelIdFamily = 'lifesync_family';
  static const String _channelIdDaily = 'lifesync_daily';

  /// Initialize notification service with all channels
  Future<void> initialize() async {
    if (_initialized) return;

    // Initialize timezone
    tz.initializeTimeZones();
    // Ideally user specific, but hardcoding for now or detecting local
    // tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    // Request permissions
    await requestPermissions();

    _initialized = true;
  }

  /// Request notification permissions
  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();

    if (status.isGranted) {
      if (await Permission.scheduleExactAlarm.isDenied) {
        await Permission.scheduleExactAlarm.request();
      }
      return true;
    }
    return false;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    return await Permission.notification.isGranted;
  }

  /// Handle notification tap
  void _handleNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;

    // Logic to handle navigation could go here
    // print('Notification tapped with payload: $payload');
  }

  // ========== GENERAL NOTIFICATION ==========

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationPriority priority = NotificationPriority.high,
    bool playSound = true,
    bool enableVibration = true,
  }) async {
    if (!await areNotificationsEnabled()) return;

    // Save to history
    await _saveNotificationToHistory(
      title: title,
      body: body,
      type: channel.name,
    );

    final channelId = _getChannelId(channel);
    final channelName = _getChannelName(channel);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _getChannelDescription(channel),
      importance: priority == NotificationPriority.high
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority == NotificationPriority.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: playSound,
      enableVibration: enableVibration,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannel channel = NotificationChannel.general,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    if (!await areNotificationsEnabled()) return;

    if (scheduledDate.isBefore(DateTime.now())) return;

    final channelId = _getChannelId(channel);
    final channelName = _getChannelName(channel);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: _getChannelDescription(channel),
      importance: priority == NotificationPriority.high
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority == NotificationPriority.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      // Handle error
    }
  }

  // --- Notification History Methods ---

  static const String _historyKey = 'notification_history';

  Future<void> _saveNotificationToHistory({
    required String title,
    required String body,
    required String type,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      final newItem = NotificationItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
        type: type,
      );

      // Add to beginning
      historyJson.insert(0, jsonEncode(newItem.toJson()));

      // Limit history to 50 items
      if (historyJson.length > 50) {
        historyJson.removeLast();
      }

      await prefs.setStringList(_historyKey, historyJson);
    } catch (e) {
      // Ignored
    }
  }

  Future<List<NotificationItem>> getNotificationHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      return historyJson
          .map((item) => NotificationItem.fromJson(jsonDecode(item)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearNotificationHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }

  Future<void> deleteNotification(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      final updatedHistory = historyJson.where((itemStr) {
        final item = NotificationItem.fromJson(jsonDecode(itemStr));
        return item.id != id;
      }).toList();

      await prefs.setStringList(_historyKey, updatedHistory);
    } catch (e) {
      // Ignored
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_historyKey) ?? [];

      final updatedHistory = historyJson.map((itemStr) {
        final item = NotificationItem.fromJson(jsonDecode(itemStr));
        return jsonEncode(item.copyWith(isRead: true).toJson());
      }).toList();

      await prefs.setStringList(_historyKey, updatedHistory);
    } catch (e) {
      // Ignored
    }
  }

  // ========== REMINDER NOTIFICATIONS ==========

  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.notificationEnabled) return;

    final notificationDate = reminder.dueDate.subtract(
      Duration(days: reminder.notificationDaysBefore ?? 1),
    );

    // Schedule notification for 'days before'
    if (notificationDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: reminder.id.hashCode,
        title: '📌 Reminder: ${reminder.title}',
        body:
            'Due on ${_formatDate(reminder.dueDate)}${reminder.amount != null ? " • ₹${reminder.amount!.toStringAsFixed(0)}" : ""}',
        scheduledDate: notificationDate,
        payload: 'reminder:${reminder.id}',
        channel: NotificationChannel.reminders,
      );
    }
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    await _notifications.cancel(reminderId.hashCode);
  }

  // ========== TASK NOTIFICATIONS ==========

  Future<void> scheduleTaskNotifications(Task task) async {
    if (task.dueDate == null || task.isCompleted) return;

    final notificationId = task.id.hashCode;

    // Notification 1 day before
    final oneDayBefore = task.dueDate!.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: '⏰ Task Due Tomorrow: ${task.title}',
        body: task.description ?? 'Priority: ${task.priority}',
        scheduledDate: oneDayBefore,
        payload: 'task:${task.id}',
        channel: NotificationChannel.tasks,
        priority: task.priority.toLowerCase() == 'high'
            ? NotificationPriority.high
            : NotificationPriority.normal,
      );
    }

    // Notification on due date
    if (task.dueDate!.isAfter(DateTime.now())) {
      final dueDateTime = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
        9, // 9 AM
      );

      await scheduleNotification(
        id: notificationId + 1,
        title: '🚨 Task Due Today: ${task.title}',
        body: task.description ?? 'Complete this task today!',
        scheduledDate: dueDateTime,
        payload: 'task:${task.id}',
        channel: NotificationChannel.tasks,
        priority: NotificationPriority.high,
      );
    }
  }

  // Compatibility with old name
  Future<void> scheduleTaskNotification(Task task) async {
    await scheduleTaskNotifications(task);
  }

  Future<void> showTaskOverdueNotification(Task task) async {
    await showNotification(
      id: ('task_overdue_${task.id}').hashCode,
      title: '⚠️ Overdue Task: ${task.title}',
      body: 'This task is overdue. Please complete it as soon as possible.',
      payload: 'task:${task.id}',
      channel: NotificationChannel.tasks,
      priority: NotificationPriority.high,
    );
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    final notificationId = taskId.hashCode;
    await _notifications.cancel(notificationId);
    await _notifications.cancel(notificationId + 1);
  }

  // ========== BUDGET & EXPENSE NOTIFICATIONS ==========

  Future<void> showBudgetAlert(
    String category,
    double percentage, {
    double spent = 0,
    double limit = 0,
  }) async {
    final id = ('budget_$category').hashCode;
    String emoji;
    String title;
    String body;
    NotificationPriority priority;

    if (percentage >= 100) {
      emoji = '🚨';
      title = 'Budget Exceeded: $category';
      body =
          'You have exceeded your budget by ${(percentage - 100).toStringAsFixed(0)}%! '
          '${limit > 0 ? "Spent: ₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}" : ""}';
      priority = NotificationPriority.high;
    } else if (percentage >= 90) {
      emoji = '⚠️';
      title = 'Budget Warning: $category';
      body =
          'You have used ${percentage.toStringAsFixed(0)}% of your budget. '
          '${limit > 0 ? "Spent: ₹${spent.toStringAsFixed(0)} / ₹${limit.toStringAsFixed(0)}" : ""}';
      priority = NotificationPriority.high;
    } else if (percentage >= 75) {
      emoji = '💡';
      title = 'Budget Notice: $category';
      body =
          'You have used ${percentage.toStringAsFixed(0)}% of your budget. '
          '${limit > 0 ? "Remaining: ₹${(limit - spent).toStringAsFixed(0)}" : ""}';
      priority = NotificationPriority.normal;
    } else {
      return;
    }

    await showNotification(
      id: id,
      title: '$emoji $title',
      body: body,
      payload: 'budget:$category',
      channel: NotificationChannel.budget,
      priority: priority,
    );
  }

  Future<void> showLargeExpenseAlert(
    Expense expense,
    double averageExpense,
  ) async {
    if (expense.amount <= averageExpense * 2) return;

    await showNotification(
      id: ('large_expense_${expense.id}').hashCode,
      title: '💰 Large Expense Recorded',
      body:
          'You spent ₹${expense.amount.toStringAsFixed(0)} on ${expense.category}. '
          'This is ${((expense.amount / averageExpense) - 1).toStringAsFixed(0)}x your average expense.',
      payload: 'expense:${expense.id}',
      channel: NotificationChannel.budget,
    );
  }

  // ========== SAVINGS GOAL NOTIFICATIONS ==========

  Future<void> scheduleSavingsGoalNotifications(SavingsGoal goal) async {
    if (goal.targetDate == null || goal.id == null) return;

    final daysUntilTarget = goal.targetDate!.difference(DateTime.now()).inDays;
    final notificationId = goal.id!.hashCode;

    // Notify 7 days before target date
    if (daysUntilTarget >= 7 && daysUntilTarget <= 8) {
      final notificationDate = goal.targetDate!.subtract(
        const Duration(days: 7),
      );
      await scheduleNotification(
        id: notificationId,
        title: '🎯 Savings Goal: ${goal.title}',
        body:
            '7 days left! Progress: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)} '
            '(${goal.progress.toStringAsFixed(0)}%)',
        scheduledDate: notificationDate,
        payload: 'savings:${goal.id}',
        channel: NotificationChannel.savings,
      );
    }

    // Notify on target date
    await scheduleNotification(
      id: notificationId + 2,
      title: '📅 Savings Goal End Date: ${goal.title}',
      body:
          'Today is your target date! Final: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
      scheduledDate: goal.targetDate!,
      payload: 'savings:${goal.id}',
      channel: NotificationChannel.savings,
      priority: NotificationPriority.high,
    );
  }

  // Compatibility alias
  Future<void> scheduleSavingsGoalNotification(SavingsGoal goal) async {
    await scheduleSavingsGoalNotifications(goal);
  }

  Future<void> showSavingsMilestone(
    SavingsGoal goal,
    double oldPercentage,
  ) async {
    final newPercentage = goal.progress;
    String? emoji;
    String? milestone;

    if (oldPercentage < 25 && newPercentage >= 25) {
      emoji = '🎯';
      milestone = '25%';
    } else if (oldPercentage < 50 && newPercentage >= 50) {
      emoji = '🎉';
      milestone = '50% (Halfway!)';
    } else if (oldPercentage < 75 && newPercentage >= 75) {
      emoji = '🌟';
      milestone = '75%';
    } else if (oldPercentage < 100 && newPercentage >= 100) {
      emoji = '🏆';
      milestone = '100% (Goal Achieved!)';
    }

    if (emoji != null && milestone != null) {
      await showNotification(
        id: ('savings_milestone_${goal.id}_$newPercentage').hashCode,
        title: '$emoji Milestone Reached: ${goal.title}',
        body:
            'You have reached $milestone of your savings goal! '
            'Saved: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
        payload: 'savings:${goal.id}',
        channel: NotificationChannel.savings,
        priority: newPercentage >= 100
            ? NotificationPriority.high
            : NotificationPriority.normal,
      );
    }
  }

  // ========== EVENT NOTIFICATIONS ==========

  Future<void> scheduleEventNotifications(FamilyEvent event) async {
    final notificationId = event.id.hashCode;

    final oneDayBefore = event.startDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: '📅 Tomorrow: ${event.title}',
        body:
            event.description ??
            'Event starts tomorrow at ${_formatTime(event.startDate)}',
        scheduledDate: oneDayBefore,
        payload: 'event:${event.id}',
        channel: NotificationChannel.events,
      );
    }

    // Notify on event day (2 hours before)
    final twoHoursBefore = event.startDate.subtract(const Duration(hours: 2));
    if (twoHoursBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId + 1,
        title: '⏰ Starting Soon: ${event.title}',
        body: event.description ?? 'Event starts in 2 hours',
        scheduledDate: twoHoursBefore,
        payload: 'event:${event.id}',
        channel: NotificationChannel.events,
        priority: NotificationPriority.high,
      );
    }
  }

  // Compatibility name
  Future<void> scheduleEventNotification(FamilyEvent event) async {
    await scheduleEventNotifications(event);
  }

  Future<void> cancelEventNotifications(String eventId) async {
    final notificationId = eventId.hashCode;
    await _notifications.cancel(notificationId);
    await _notifications.cancel(notificationId + 1);
  }

  // ========== HEALTH NOTIFICATIONS ==========

  Future<void> scheduleHealthVisitNotifications(HealthRecord record) async {
    if (record.nextVisit == null) return;

    final notificationId = record.id.hashCode;
    final visitDate = record.nextVisit!;

    // Notify 1 day before
    final oneDayBefore = visitDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId + 1,
        title: '🏥 Health Visit Tomorrow',
        body:
            record.description ??
            'You have a health visit scheduled for tomorrow',
        scheduledDate: oneDayBefore,
        payload: 'health:${record.id}',
        channel: NotificationChannel.health,
        priority: NotificationPriority.high,
      );
    }
  }

  // ========== FAMILY NOTIFICATIONS ==========

  Future<void> showFamilyMemberAddedNotification(String memberName) async {
    await showNotification(
      id: ('family_added_$memberName').hashCode,
      title: '👨‍👩‍👧‍👦 New Family Member',
      body: '$memberName has been added to your family',
      channel: NotificationChannel.family,
    );
  }

  // ========== DAILY SUMMARY ==========

  Future<void> scheduleDailySummary({
    required int tasksToday,
    required int remindersToday,
    required double todayExpenses,
    int hour = 8,
  }) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final notificationTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      hour,
      0,
    );

    await scheduleNotification(
      id: 'daily_summary'.hashCode,
      title: '☀️ Good Morning! Here\'s Your Summary',
      body:
          '$tasksToday tasks, $remindersToday reminders, ₹${todayExpenses.toStringAsFixed(0)} expenses today',
      scheduledDate: notificationTime,
      payload: 'summary',
      channel: NotificationChannel.daily,
    );
  }

  // ========== UTILITY METHODS ==========

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // ========== HELPER METHODS ==========

  String _getChannelId(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return _channelIdGeneral;
      case NotificationChannel.reminders:
        return _channelIdReminders;
      case NotificationChannel.tasks:
        return _channelIdTasks;
      case NotificationChannel.budget:
        return _channelIdBudget;
      case NotificationChannel.savings:
        return _channelIdSavings;
      case NotificationChannel.events:
        return _channelIdEvents;
      case NotificationChannel.health:
        return _channelIdHealth;
      case NotificationChannel.family:
        return _channelIdFamily;
      case NotificationChannel.daily:
        return _channelIdDaily;
    }
  }

  String _getChannelName(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return 'General Notifications';
      case NotificationChannel.reminders:
        return 'Reminders';
      case NotificationChannel.tasks:
        return 'Tasks';
      case NotificationChannel.budget:
        return 'Budget Alerts';
      case NotificationChannel.savings:
        return 'Savings Goals';
      case NotificationChannel.events:
        return 'Family Events';
      case NotificationChannel.health:
        return 'Health Alerts';
      case NotificationChannel.family:
        return 'Family Updates';
      case NotificationChannel.daily:
        return 'Daily Summary';
    }
  }

  String _getChannelDescription(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.general:
        return 'General app notifications';
      case NotificationChannel.reminders:
        return 'Reminders for payments and bills';
      case NotificationChannel.tasks:
        return 'Task deadlines and reminders';
      case NotificationChannel.budget:
        return 'Budget overspending alerts';
      case NotificationChannel.savings:
        return 'Savings goal milestones and deadlines';
      case NotificationChannel.events:
        return 'Upcoming family events';
      case NotificationChannel.health:
        return 'Health checkup and medication reminders';
      case NotificationChannel.family:
        return 'Notifications about family members';
      case NotificationChannel.daily:
        return 'Daily morning summary';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

enum NotificationChannel {
  general,
  reminders,
  tasks,
  budget,
  savings,
  events,
  health,
  family,
  daily,
}

enum NotificationPriority { normal, high }
