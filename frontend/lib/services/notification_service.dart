import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/reminder.dart';
import '../models/task.dart';
import '../models/savings_goal.dart';
import '../models/family_event.dart';
import '../models/health_record.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // Handle notification tap
      },
    );

    _initialized = true;
  }

  Future<void> requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lifesync_channel',
      'LifeSync Notifications',
      channelDescription: 'Notifications for LifeSync app',
      importance: priority == NotificationPriority.high
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority == NotificationPriority.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    await _notifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationPriority priority = NotificationPriority.high,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'lifesync_scheduled',
      'Scheduled Notifications',
      channelDescription: 'Scheduled reminders for LifeSync',
      importance: priority == NotificationPriority.high
          ? Importance.high
          : Importance.defaultImportance,
      priority: priority == NotificationPriority.high
          ? Priority.high
          : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
    );

    final details = NotificationDetails(android: androidDetails);

    // Ensure scheduled date is in the future
    if (scheduledDate.isBefore(DateTime.now())) {
      return; // Skip past notifications
    }

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: payload,
    );
  }

  // ===== REMINDER NOTIFICATIONS =====
  Future<void> scheduleReminderNotification(Reminder reminder) async {
    if (!reminder.notificationEnabled) return;

    final dueDate = reminder.dueDate;
    final notificationDate = dueDate.subtract(
      Duration(days: reminder.notificationDaysBefore ?? 1),
    );

    final notificationId = reminder.id.hashCode;

    await scheduleNotification(
      id: notificationId,
      title: 'Reminder: ${reminder.title}',
      body:
          'Due on ${_formatDate(dueDate)}${reminder.amount != null ? " • ₹${reminder.amount!.toStringAsFixed(0)}" : ""}',
      scheduledDate: notificationDate,
      payload: 'reminder:${reminder.id}',
    );
  }

  // ===== TASK NOTIFICATIONS =====
  Future<void> scheduleTaskNotification(Task task) async {
    if (task.dueDate == null || task.isCompleted) return;

    final notificationId = task.id.hashCode;

    // Schedule notification 1 day before due date
    final notificationDate = task.dueDate!.subtract(const Duration(days: 1));

    if (notificationDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: 'Task Due Tomorrow: ${task.title}',
        body: task.description ?? 'Priority: ${task.priority}',
        scheduledDate: notificationDate,
        payload: 'task:${task.id}',
        priority: task.priority.toLowerCase() == 'high'
            ? NotificationPriority.high
            : NotificationPriority.normal,
      );
    }

    // Schedule notification on due date
    if (task.dueDate!.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId + 1,
        title: 'Task Due Today: ${task.title}',
        body: task.description ?? 'Complete this task today!',
        scheduledDate: task.dueDate!,
        payload: 'task:${task.id}',
        priority: NotificationPriority.high,
      );
    }
  }

  Future<void> showTaskOverdueNotification(Task task) async {
    await showNotification(
      id: ('task_overdue_${task.id}').hashCode,
      title: '⚠️ Overdue Task: ${task.title}',
      body: 'This task is overdue. Please complete it as soon as possible.',
      payload: 'task:${task.id}',
      priority: NotificationPriority.high,
    );
  }

  // ===== BUDGET NOTIFICATIONS =====
  Future<void> showBudgetAlert(String category, double percentage) async {
    final id = ('budget_$category').hashCode;
    String title;
    String body;

    if (percentage >= 100) {
      title = '🚨 Budget Exceeded: $category';
      body =
          'You have exceeded your budget by ${(percentage - 100).toStringAsFixed(0)}%!';
    } else if (percentage >= 90) {
      title = '⚠️ Budget Warning: $category';
      body = 'You have used ${percentage.toStringAsFixed(0)}% of your budget.';
    } else if (percentage >= 75) {
      title = '💡 Budget Notice: $category';
      body = 'You have used ${percentage.toStringAsFixed(0)}% of your budget.';
    } else {
      return; // Don't notify for lower percentages
    }

    await showNotification(
      id: id,
      title: title,
      body: body,
      payload: 'budget:$category',
      priority: percentage >= 100
          ? NotificationPriority.high
          : NotificationPriority.normal,
    );
  }

  // ===== SAVINGS GOAL NOTIFICATIONS =====
  Future<void> scheduleSavingsGoalNotification(SavingsGoal goal) async {
    final notificationId = goal.id?.hashCode ?? 0;
    if (goal.targetDate == null) return;
    final daysUntilTarget = goal.targetDate!.difference(DateTime.now()).inDays;

    // Notify when 7 days remain
    if (daysUntilTarget == 7) {
      await scheduleNotification(
        id: notificationId,
        title: 'Savings Goal: ${goal.title}',
        body:
            '7 days left to reach your goal! Current: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
        scheduledDate: DateTime.now().add(const Duration(seconds: 5)),
        payload: 'savings:${goal.id}',
      );
    }

    // Notify on target date
    await scheduleNotification(
      id: notificationId + 1,
      title: 'Savings Goal End Date: ${goal.title}',
      body:
          'Today is your target date! Progress: ₹${goal.currentAmount.toStringAsFixed(0)} / ₹${goal.targetAmount.toStringAsFixed(0)}',
      scheduledDate: goal.targetDate!,
      payload: 'savings:${goal.id}',
    );
  }

  Future<void> showSavingsGoalMilestone(
    SavingsGoal goal,
    double percentage,
  ) async {
    if (percentage >= 100) {
      await showNotification(
        id: ('savings_complete_${goal.id}').hashCode,
        title: '🎉 Goal Achieved: ${goal.title}',
        body:
            'Congratulations! You have reached your savings goal of ₹${goal.targetAmount.toStringAsFixed(0)}!',
        payload: 'savings:${goal.id}',
        priority: NotificationPriority.high,
      );
    } else if (percentage >= 75) {
      await showNotification(
        id: ('savings_75_${goal.id}').hashCode,
        title: '🎯 75% Milestone: ${goal.title}',
        body: 'Great progress! You are 75% towards your goal!',
        payload: 'savings:${goal.id}',
      );
    } else if (percentage >= 50) {
      await showNotification(
        id: ('savings_50_${goal.id}').hashCode,
        title: '🎯 Halfway There: ${goal.title}',
        body: 'You have reached 50% of your savings goal!',
        payload: 'savings:${goal.id}',
      );
    } else if (percentage >= 25) {
      await showNotification(
        id: ('savings_25_${goal.id}').hashCode,
        title: '🎯 25% Complete: ${goal.title}',
        body: 'Keep going! You are 25% towards your goal!',
        payload: 'savings:${goal.id}',
      );
    }
  }

  // ===== EVENT NOTIFICATIONS =====
  Future<void> scheduleEventNotification(FamilyEvent event) async {
    final notificationId = event.id.hashCode;

    // Notify 1 day before
    final oneDayBefore = event.startDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: 'Tomorrow: ${event.title}',
        body:
            event.description ??
            'Event starts tomorrow at ${_formatDateTime(event.startDate)}',
        scheduledDate: oneDayBefore,
        payload: 'event:${event.id}',
      );
    }

    // Notify on event day
    if (event.startDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId + 1,
        title: 'Today: ${event.title}',
        body:
            event.description ??
            'Event today at ${_formatDateTime(event.startDate)}',
        scheduledDate: event.startDate,
        payload: 'event:${event.id}',
        priority: NotificationPriority.high,
      );
    }
  }

  // ===== HEALTH NOTIFICATIONS =====
  Future<void> scheduleHealthVisitNotification(HealthRecord record) async {
    if (record.nextVisit == null) return;

    final notificationId = record.id.hashCode;
    final visitDate = record.nextVisit!;

    // Notify 1 day before
    final oneDayBefore = visitDate.subtract(const Duration(days: 1));
    if (oneDayBefore.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId,
        title: 'Health Visit Tomorrow',
        body:
            record.description ??
            'You have a health visit scheduled for tomorrow',
        scheduledDate: oneDayBefore,
        payload: 'health:${record.id}',
      );
    }

    // Notify on visit day
    if (visitDate.isAfter(DateTime.now())) {
      await scheduleNotification(
        id: notificationId + 1,
        title: 'Health Visit Today',
        body:
            record.description ?? 'You have a health visit scheduled for today',
        scheduledDate: visitDate,
        payload: 'health:${record.id}',
        priority: NotificationPriority.high,
      );
    }
  }

  // ===== SHOPPING LIST NOTIFICATIONS =====
  Future<void> showShoppingListReminder(int itemCount) async {
    if (itemCount == 0) return;

    await showNotification(
      id: 'shopping_reminder'.hashCode,
      title: '🛒 Shopping List Reminder',
      body:
          'You have $itemCount item${itemCount > 1 ? 's' : ''} in your shopping list',
      payload: 'shopping',
    );
  }

  // ===== DAILY SUMMARY NOTIFICATION =====
  Future<void> scheduleDailySummary({
    required int tasksToday,
    required int remindersToday,
    required double todayExpenses,
  }) async {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final notificationTime = DateTime(
      tomorrow.year,
      tomorrow.month,
      tomorrow.day,
      8,
      0,
    );

    await scheduleNotification(
      id: 'daily_summary'.hashCode,
      title: '☀️ Good Morning! Here\'s your summary',
      body:
          '$tasksToday tasks, $remindersToday reminders, ₹${todayExpenses.toStringAsFixed(0)} expenses today',
      scheduledDate: notificationTime,
      payload: 'summary',
    );
  }

  // ===== UTILITY METHODS =====
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelTaskNotifications(String taskId) async {
    final notificationId = taskId.hashCode;
    await cancelNotification(notificationId);
    await cancelNotification(notificationId + 1);
  }

  Future<void> cancelReminderNotification(String reminderId) async {
    await cancelNotification(reminderId.hashCode);
  }

  Future<void> cancelEventNotifications(String eventId) async {
    final notificationId = eventId.hashCode;
    await cancelNotification(notificationId);
    await cancelNotification(notificationId + 1);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day}/${date.month}/${date.year} $hour:${date.minute.toString().padLeft(2, '0')} $period';
  }
}

enum NotificationPriority { normal, high }
