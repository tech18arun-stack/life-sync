import '../models/budget.dart';
import '../models/family_member.dart';
import '../models/family_number.dart';
import '../models/task.dart';
import '../models/savings_goal.dart';
import '../models/reminder.dart';
import '../models/health_record.dart';
import '../services/appwrite_service.dart';
import 'base_repository.dart';

export 'base_repository.dart';
export 'incomes_repository.dart';
export 'expenses_repository.dart';

/// Budgets Repository
class BudgetsRepository implements BaseRepository<Budget> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<Budget> create(Budget item) async {
    final data = await _appwrite.createBudget(item.toJson());
    return Budget.fromJson(data);
  }

  @override
  Future<List<Budget>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getBudgets(
      month: filters?['month'] as int?,
      year: filters?['year'] as int?,
    );
    return data.map((json) => Budget.fromJson(json)).toList();
  }

  @override
  Future<Budget?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.budgetsCollection,
      documentId: id,
    );
    if (data == null) return null;
    return Budget.fromJson(data);
  }

  @override
  Future<Budget> update(String id, Budget item) async {
    final data = await _appwrite.updateBudget(id, item.toJson());
    return Budget.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteBudget(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get budgets for current month
  Future<List<Budget>> getCurrentMonthBudgets() async {
    final now = DateTime.now();
    return getAll(filters: {'month': now.month, 'year': now.year});
  }

  /// Update spent amount for a budget
  Future<Budget> updateSpentAmount(String id, double spentAmount) async {
    final budget = await getById(id);
    if (budget == null) {
      throw Exception('Budget not found');
    }
    final updated = budget.copyWith(spentAmount: spentAmount);
    return update(id, updated);
  }
}

/// Family Members Repository
class FamilyMembersRepository implements BaseRepository<FamilyMember> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<FamilyMember> create(FamilyMember item) async {
    final data = await _appwrite.createFamilyMember(item.toJson());
    return FamilyMember.fromJson(data);
  }

  @override
  Future<List<FamilyMember>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getFamilyMembers();
    return data.map((json) => FamilyMember.fromJson(json)).toList();
  }

  @override
  Future<FamilyMember?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.familyMembersCollection,
      documentId: id,
    );
    if (data == null) return null;
    return FamilyMember.fromJson(data);
  }

  @override
  Future<FamilyMember> update(String id, FamilyMember item) async {
    final data = await _appwrite.updateFamilyMember(id, item.toJson());
    return FamilyMember.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteFamilyMember(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }
}

/// Family Numbers Repository
class FamilyNumbersRepository implements BaseRepository<FamilyNumber> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<FamilyNumber> create(FamilyNumber item) async {
    final data = await _appwrite.createFamilyNumber(item.toJson());
    return FamilyNumber.fromJson(data);
  }

  @override
  Future<List<FamilyNumber>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getFamilyNumbers();
    return data.map((json) => FamilyNumber.fromJson(json)).toList();
  }

  @override
  Future<FamilyNumber?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.familyNumbersCollection,
      documentId: id,
    );
    if (data == null) return null;
    return FamilyNumber.fromJson(data);
  }

  @override
  Future<FamilyNumber> update(String id, FamilyNumber item) async {
    final data = await _appwrite.updateFamilyNumber(id, item.toJson());
    return FamilyNumber.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteFamilyNumber(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get emergency contacts
  Future<List<FamilyNumber>> getEmergencyContacts() async {
    final all = await getAll();
    return all.where((fn) => fn.isEmergency).toList();
  }
}

/// Tasks Repository
class TasksRepository implements BaseRepository<Task> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<Task> create(Task item) async {
    final data = await _appwrite.createTask(item.toJson());
    return Task.fromJson(data);
  }

  @override
  Future<List<Task>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getTasks(
      status: filters?['status'] as String?,
      priority: filters?['priority'] as String?,
      isCompleted: filters?['is_completed'] as bool?,
    );
    return data.map((json) => Task.fromJson(json)).toList();
  }

  @override
  Future<Task?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.tasksCollection,
      documentId: id,
    );
    if (data == null) return null;
    return Task.fromJson(data);
  }

  @override
  Future<Task> update(String id, Task item) async {
    final data = await _appwrite.updateTask(id, item.toJson());
    return Task.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteTask(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get pending tasks
  Future<List<Task>> getPendingTasks() async {
    return getAll(filters: {'is_completed': false});
  }

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks() async {
    return getAll(filters: {'is_completed': true});
  }

  /// Mark task as completed
  Future<Task> markAsCompleted(String id) async {
    final task = await getById(id);
    if (task == null) {
      throw Exception('Task not found');
    }
    final updated = task.copyWith(
      isCompleted: true,
      completedAt: DateTime.now(),
      status: 'Completed',
    );
    return update(id, updated);
  }
}

/// Savings Goals Repository
class SavingsGoalsRepository implements BaseRepository<SavingsGoal> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<SavingsGoal> create(SavingsGoal item) async {
    final data = await _appwrite.createSavingsGoal(item.toJson());
    return SavingsGoal.fromJson(data);
  }

  @override
  Future<List<SavingsGoal>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getSavingsGoals(
      category: filters?['category'] as String?,
      isCompleted: filters?['is_completed'] as bool?,
    );
    return data.map((json) => SavingsGoal.fromJson(json)).toList();
  }

  @override
  Future<SavingsGoal?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.savingsGoalsCollection,
      documentId: id,
    );
    if (data == null) return null;
    return SavingsGoal.fromJson(data);
  }

  @override
  Future<SavingsGoal> update(String id, SavingsGoal item) async {
    final data = await _appwrite.updateSavingsGoal(id, item.toJson());
    return SavingsGoal.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteSavingsGoal(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Add contribution to savings goal
  Future<SavingsGoal> addContribution(String id, double amount) async {
    final goal = await getById(id);
    if (goal == null) {
      throw Exception('Savings goal not found');
    }
    final updated = goal.copyWith(
      currentAmount: goal.currentAmount + amount,
    );
    return update(id, updated);
  }

  /// Get active savings goals
  Future<List<SavingsGoal>> getActiveGoals() async {
    return getAll(filters: {'is_completed': false});
  }
}

/// Reminders Repository
class RemindersRepository implements BaseRepository<Reminder> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<Reminder> create(Reminder item) async {
    final data = await _appwrite.createReminder(item.toJson());
    return Reminder.fromJson(data);
  }

  @override
  Future<List<Reminder>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getReminders(
      isPaid: filters?['is_paid'] as bool?,
      type: filters?['type'] as String?,
    );
    return data.map((json) => Reminder.fromJson(json)).toList();
  }

  @override
  Future<Reminder?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.remindersCollection,
      documentId: id,
    );
    if (data == null) return null;
    return Reminder.fromJson(data);
  }

  @override
  Future<Reminder> update(String id, Reminder item) async {
    final data = await _appwrite.updateReminder(id, item.toJson());
    return Reminder.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteReminder(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get unpaid reminders
  Future<List<Reminder>> getUnpaidReminders() async {
    return getAll(filters: {'is_paid': false});
  }

  /// Get overdue reminders
  Future<List<Reminder>> getOverdueReminders() async {
    final unpaid = await getUnpaidReminders();
    return unpaid.where((r) => r.isOverdue).toList();
  }

  /// Mark reminder as paid
  Future<Reminder> markAsPaid(String id) async {
    final reminder = await getById(id);
    if (reminder == null) {
      throw Exception('Reminder not found');
    }
    final updated = reminder.copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
    );
    return update(id, updated);
  }
}

/// Health Records Repository
class HealthRecordsRepository implements BaseRepository<HealthRecord> {
  final AppwriteService _appwrite = AppwriteService();

  @override
  Future<HealthRecord> create(HealthRecord item) async {
    final data = await _appwrite.createHealthRecord(item.toJson());
    return HealthRecord.fromJson(data);
  }

  @override
  Future<List<HealthRecord>> getAll({Map<String, dynamic>? filters}) async {
    final data = await _appwrite.getHealthRecords(
      memberName: filters?['member_name'] as String?,
      recordType: filters?['record_type'] as String?,
    );
    return data.map((json) => HealthRecord.fromJson(json)).toList();
  }

  @override
  Future<HealthRecord?> getById(String id) async {
    final data = await _appwrite.getDocument(
      collectionId: AppwriteService.healthRecordsCollection,
      documentId: id,
    );
    if (data == null) return null;
    return HealthRecord.fromJson(data);
  }

  @override
  Future<HealthRecord> update(String id, HealthRecord item) async {
    final data = await _appwrite.updateHealthRecord(id, item.toJson());
    return HealthRecord.fromJson(data);
  }

  @override
  Future<void> delete(String id) async {
    await _appwrite.deleteHealthRecord(id);
  }

  @override
  Future<void> deleteAll(List<String> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  /// Get records by member name
  Future<List<HealthRecord>> getByMember(String memberName) async {
    final data = await _appwrite.getHealthRecords(memberName: memberName);
    return data.map((json) => HealthRecord.fromJson(json)).toList();
  }

  /// Get records by type
  Future<List<HealthRecord>> getByType(String recordType) async {
    final data = await _appwrite.getHealthRecords(recordType: recordType);
    return data.map((json) => HealthRecord.fromJson(json)).toList();
  }

  /// Add attachment URLs to health record
  Future<HealthRecord> addAttachments(
    String id,
    List<String> attachmentUrls,
  ) async {
    final record = await getById(id);
    if (record == null) {
      throw Exception('Health record not found');
    }

    final existingAttachments = record.attachments ?? [];
    final updatedAttachments = [...existingAttachments, ...attachmentUrls];

    final updated = record.copyWith(attachments: updatedAttachments);
    return update(id, updated);
  }
}
