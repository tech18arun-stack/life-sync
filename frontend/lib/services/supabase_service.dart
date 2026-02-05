import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  late SupabaseClient _client;

  SupabaseService() {
    _client = Supabase.instance.client;
  }

  SupabaseClient get client => _client;

  // Generic methods for CRUD operations
  Future<List<Map<String, dynamic>>> selectFromTable(
    String table, {
    Map<String, dynamic>? filters,
  }) async {
    try {
      var query = _client.from(table).select();

      // Add user ID filter automatically if user is logged in
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      if (filters != null) {
        filters.forEach((key, value) {
          if (value != null) {
            query = query.eq(key, value);
          }
        });
      }

      final response = await query;
      return response;
    } catch (e) {
      debugPrint('Error selecting from $table: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> insertIntoTable(
    String table,
    Map<String, dynamic> data,
  ) async {
    try {
      // Add user ID to the data if user is logged in
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        data['user_id'] = userId;
      }

      // Use .select() to return the inserted row
      final response = await _client.from(table).insert(data).select().single();

      return response;
    } catch (e) {
      debugPrint('Error inserting into $table: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateInTable(
    String table,
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      // Don't add user_id to the update data, just ensure the update is scoped to the user
      final userId = Supabase.instance.client.auth.currentUser?.id;

      var query = _client.from(table).update(data).eq('id', id);
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      // Use .select() to return the updated row
      final response = await query.select().single();
      return response;
    } catch (e) {
      debugPrint('Error updating $table: $e');
      rethrow;
    }
  }

  Future<void> deleteFromTable(String table, String id) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      var query = _client.from(table).delete().eq('id', id);
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      await query;
    } catch (e) {
      debugPrint('Error deleting from $table: $e');
      rethrow;
    }
  }

  // Specific methods for each entity

  // Expenses
  Future<List<Map<String, dynamic>>> getExpenses({String? category}) async {
    Map<String, dynamic> filters = {};
    if (category != null) filters['category'] = category;

    return await selectFromTable('expenses', filters: filters);
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    return await insertIntoTable('expenses', data);
  }

  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('expenses', id, data);
  }

  Future<void> deleteExpense(String id) async {
    await deleteFromTable('expenses', id);
  }

  // Incomes
  Future<List<Map<String, dynamic>>> getIncomes({String? source}) async {
    Map<String, dynamic> filters = {};
    if (source != null) filters['source'] = source;

    return await selectFromTable('incomes', filters: filters);
  }

  Future<Map<String, dynamic>> createIncome(Map<String, dynamic> data) async {
    return await insertIntoTable('incomes', data);
  }

  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('incomes', id, data);
  }

  Future<void> deleteIncome(String id) async {
    await deleteFromTable('incomes', id);
  }

  // Budgets
  Future<List<Map<String, dynamic>>> getBudgets({int? month, int? year}) async {
    Map<String, dynamic> filters = {};
    if (month != null) filters['month'] = month;
    if (year != null) filters['year'] = year;

    return await selectFromTable('budgets', filters: filters);
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    return await insertIntoTable('budgets', data);
  }

  Future<Map<String, dynamic>> updateBudget(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('budgets', id, data);
  }

  Future<void> deleteBudget(String id) async {
    await deleteFromTable('budgets', id);
  }

  // Family Members
  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    return await selectFromTable('family_members');
  }

  Future<Map<String, dynamic>> createFamilyMember(
    Map<String, dynamic> data,
  ) async {
    return await insertIntoTable('family_members', data);
  }

  Future<Map<String, dynamic>> updateFamilyMember(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('family_members', id, data);
  }

  Future<void> deleteFamilyMember(String id) async {
    await deleteFromTable('family_members', id);
  }

  // Family Numbers
  Future<List<Map<String, dynamic>>> getFamilyNumbers({
    String? category,
    bool? isEmergency,
  }) async {
    Map<String, dynamic> filters = {};
    if (category != null) filters['category'] = category;
    if (isEmergency != null) filters['is_emergency'] = isEmergency;

    return await selectFromTable('family_numbers', filters: filters);
  }

  Future<Map<String, dynamic>> createFamilyNumber(
    Map<String, dynamic> data,
  ) async {
    return await insertIntoTable('family_numbers', data);
  }

  Future<Map<String, dynamic>> updateFamilyNumber(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('family_numbers', id, data);
  }

  Future<void> deleteFamilyNumber(String id) async {
    await deleteFromTable('family_numbers', id);
  }

  // Tasks
  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? priority,
    bool? isCompleted,
  }) async {
    Map<String, dynamic> filters = {};
    if (status != null) filters['status'] = status;
    if (priority != null) filters['priority'] = priority;
    if (isCompleted != null) filters['is_completed'] = isCompleted;

    return await selectFromTable('tasks', filters: filters);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    return await insertIntoTable('tasks', data);
  }

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('tasks', id, data);
  }

  Future<void> deleteTask(String id) async {
    await deleteFromTable('tasks', id);
  }

  // Savings Goals
  Future<List<Map<String, dynamic>>> getSavingsGoals({
    String? category,
    bool? isCompleted,
  }) async {
    Map<String, dynamic> filters = {};
    if (category != null) filters['category'] = category;
    if (isCompleted != null) filters['is_completed'] = isCompleted;

    return await selectFromTable('savings_goals', filters: filters);
  }

  Future<Map<String, dynamic>> createSavingsGoal(
    Map<String, dynamic> data,
  ) async {
    return await insertIntoTable('savings_goals', data);
  }

  Future<Map<String, dynamic>> updateSavingsGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('savings_goals', id, data);
  }

  Future<void> deleteSavingsGoal(String id) async {
    await deleteFromTable('savings_goals', id);
  }

  // Reminders
  Future<List<Map<String, dynamic>>> getReminders({
    bool? isPaid,
    String? type,
  }) async {
    Map<String, dynamic> filters = {};
    if (isPaid != null) filters['is_paid'] = isPaid;
    if (type != null) filters['type'] = type;

    return await selectFromTable('reminders', filters: filters);
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    return await insertIntoTable('reminders', data);
  }

  Future<Map<String, dynamic>> updateReminder(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('reminders', id, data);
  }

  Future<void> deleteReminder(String id) async {
    await deleteFromTable('reminders', id);
  }

  // Health Records
  Future<List<Map<String, dynamic>>> getHealthRecords({
    String? memberName,
    String? recordType,
  }) async {
    Map<String, dynamic> filters = {};
    if (memberName != null) filters['member_name'] = memberName;
    if (recordType != null) filters['record_type'] = recordType;

    return await selectFromTable('health_records', filters: filters);
  }

  Future<Map<String, dynamic>> createHealthRecord(
    Map<String, dynamic> data,
  ) async {
    return await insertIntoTable('health_records', data);
  }

  Future<Map<String, dynamic>> updateHealthRecord(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await updateInTable('health_records', id, data);
  }

  Future<void> deleteHealthRecord(String id) async {
    await deleteFromTable('health_records', id);
  }

  // User Profiles
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createUserProfile(
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .insert(data)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .update(data)
          .eq('id', id)
          .single();
      return response;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getClientUsers(String adminId) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('parent_user_id', adminId)
          .eq('user_type', 'client');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting client users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyUserProfiles(
    String familyId,
  ) async {
    try {
      final response = await _client
          .from('user_profiles')
          .select()
          .eq('family_id', familyId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting family user profiles: $e');
      return [];
    }
  }
}
