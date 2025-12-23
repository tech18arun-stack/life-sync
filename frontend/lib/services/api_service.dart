import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

/// API Service for MongoDB Backend Communication
/// Handles all HTTP requests to the Node.js/Express backend
class ApiService {
  // Base URL for the API
  // static const String _baseUrl = 'http://10.0.2.2:3001/api'; // Android Emulator localhost
  // static const String _baseUrl = 'http://localhost:3001/api'; // Local development
  static const String _baseUrl =
      'https://life-sync.onrender.com/api'; // Production (Render)

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // HTTP Headers with auth token
  Map<String, String> get _headers {
    final token = AuthService().token;
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ======================== GENERIC HTTP METHODS ========================

  Future<dynamic> _get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$_baseUrl$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final response = await http.get(uri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      debugPrint('GET Error: $e');
      rethrow;
    }
  }

  Future<dynamic> _post(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('POST Error: $e');
      rethrow;
    }
  }

  Future<dynamic> _put(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PUT Error: $e');
      rethrow;
    }
  }

  Future<dynamic> _patch(String endpoint, Map<String, dynamic> data) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('PATCH Error: $e');
      rethrow;
    }
  }

  Future<dynamic> _delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      debugPrint('DELETE Error: $e');
      rethrow;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw ApiException(
        error['error'] ?? 'Unknown error',
        response.statusCode,
      );
    }
  }

  // ======================== HEALTH CHECK ========================

  Future<Map<String, dynamic>> healthCheck() async {
    return await _get('/health');
  }

  // ======================== FAMILY MEMBERS ========================

  Future<List<dynamic>> getFamilyMembers() async {
    return await _get('/family-members');
  }

  Future<dynamic> getFamilyMember(String id) async {
    return await _get('/family-members/$id');
  }

  Future<dynamic> createFamilyMember(Map<String, dynamic> data) async {
    return await _post('/family-members', data);
  }

  Future<dynamic> updateFamilyMember(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _put('/family-members/$id', data);
  }

  Future<void> deleteFamilyMember(String id) async {
    await _delete('/family-members/$id');
  }

  // ======================== FAMILY NUMBERS ========================

  Future<List<dynamic>> getFamilyNumbers({
    String? category,
    bool? isEmergency,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (isEmergency != null) params['isEmergency'] = isEmergency.toString();
    return await _get(
      '/family-numbers',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<List<dynamic>> getEmergencyContacts() async {
    return await _get('/family-numbers/emergency');
  }

  Future<dynamic> createFamilyNumber(Map<String, dynamic> data) async {
    return await _post('/family-numbers', data);
  }

  Future<dynamic> updateFamilyNumber(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _put('/family-numbers/$id', data);
  }

  Future<void> deleteFamilyNumber(String id) async {
    await _delete('/family-numbers/$id');
  }

  // ======================== EXPENSES ========================

  Future<List<dynamic>> getExpenses({String? category, int? limit}) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (limit != null) params['limit'] = limit.toString();
    return await _get(
      '/expenses',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<Map<String, dynamic>> getMonthlyExpenseSummary(
    int month,
    int year,
  ) async {
    return await _get(
      '/expenses/summary/monthly',
      queryParams: {'month': month.toString(), 'year': year.toString()},
    );
  }

  Future<dynamic> createExpense(Map<String, dynamic> data) async {
    return await _post('/expenses', data);
  }

  Future<dynamic> updateExpense(String id, Map<String, dynamic> data) async {
    return await _put('/expenses/$id', data);
  }

  Future<void> deleteExpense(String id) async {
    await _delete('/expenses/$id');
  }

  // ======================== INCOMES ========================

  Future<List<dynamic>> getIncomes({String? source, int? limit}) async {
    final params = <String, String>{};
    if (source != null) params['source'] = source;
    if (limit != null) params['limit'] = limit.toString();
    return await _get(
      '/incomes',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<Map<String, dynamic>> getMonthlyIncomeSummary(
    int month,
    int year,
  ) async {
    return await _get(
      '/incomes/summary/monthly',
      queryParams: {'month': month.toString(), 'year': year.toString()},
    );
  }

  Future<dynamic> createIncome(Map<String, dynamic> data) async {
    return await _post('/incomes', data);
  }

  Future<dynamic> updateIncome(String id, Map<String, dynamic> data) async {
    return await _put('/incomes/$id', data);
  }

  Future<void> deleteIncome(String id) async {
    await _delete('/incomes/$id');
  }

  // ======================== TASKS ========================

  Future<List<dynamic>> getTasks({
    String? status,
    String? priority,
    bool? isCompleted,
  }) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    if (isCompleted != null) params['isCompleted'] = isCompleted.toString();
    return await _get('/tasks', queryParams: params.isNotEmpty ? params : null);
  }

  Future<List<dynamic>> getTodayTasks() async {
    return await _get('/tasks/today');
  }

  Future<List<dynamic>> getOverdueTasks() async {
    return await _get('/tasks/overdue');
  }

  Future<dynamic> createTask(Map<String, dynamic> data) async {
    return await _post('/tasks', data);
  }

  Future<dynamic> updateTask(String id, Map<String, dynamic> data) async {
    return await _put('/tasks/$id', data);
  }

  Future<dynamic> completeTask(String id) async {
    return await _patch('/tasks/$id/complete', {});
  }

  Future<void> deleteTask(String id) async {
    await _delete('/tasks/$id');
  }

  // ======================== BUDGETS ========================

  Future<List<dynamic>> getBudgets({
    int? month,
    int? year,
    bool? isActive,
  }) async {
    final params = <String, String>{};
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    if (isActive != null) params['isActive'] = isActive.toString();
    return await _get(
      '/budgets',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<List<dynamic>> getCurrentBudgets() async {
    return await _get('/budgets/current');
  }

  Future<List<dynamic>> getOverBudgets() async {
    return await _get('/budgets/over-budget');
  }

  Future<dynamic> createBudget(Map<String, dynamic> data) async {
    return await _post('/budgets', data);
  }

  Future<dynamic> updateBudget(String id, Map<String, dynamic> data) async {
    return await _put('/budgets/$id', data);
  }

  Future<dynamic> addBudgetSpending(String id, double amount) async {
    return await _patch('/budgets/$id/spend', {'amount': amount});
  }

  Future<void> deleteBudget(String id) async {
    await _delete('/budgets/$id');
  }

  // ======================== SAVINGS GOALS ========================

  Future<List<dynamic>> getSavingsGoals({
    String? category,
    bool? isCompleted,
  }) async {
    final params = <String, String>{};
    if (category != null) params['category'] = category;
    if (isCompleted != null) params['isCompleted'] = isCompleted.toString();
    return await _get(
      '/savings',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<Map<String, dynamic>> getSavingsSummary() async {
    return await _get('/savings/summary');
  }

  Future<dynamic> createSavingsGoal(Map<String, dynamic> data) async {
    return await _post('/savings', data);
  }

  Future<dynamic> updateSavingsGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _put('/savings/$id', data);
  }

  Future<dynamic> contributeSavings(String id, double amount) async {
    return await _patch('/savings/$id/contribute', {'amount': amount});
  }

  Future<void> deleteSavingsGoal(String id) async {
    await _delete('/savings/$id');
  }

  // ======================== REMINDERS ========================

  Future<List<dynamic>> getReminders({bool? isPaid, String? type}) async {
    final params = <String, String>{};
    if (isPaid != null) params['isPaid'] = isPaid.toString();
    if (type != null) params['type'] = type;
    return await _get(
      '/reminders',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<List<dynamic>> getPendingReminders() async {
    return await _get('/reminders/pending');
  }

  Future<List<dynamic>> getOverdueReminders() async {
    return await _get('/reminders/overdue');
  }

  Future<dynamic> createReminder(Map<String, dynamic> data) async {
    return await _post('/reminders', data);
  }

  Future<dynamic> updateReminder(String id, Map<String, dynamic> data) async {
    return await _put('/reminders/$id', data);
  }

  Future<dynamic> markReminderPaid(String id) async {
    return await _patch('/reminders/$id/pay', {});
  }

  Future<void> deleteReminder(String id) async {
    await _delete('/reminders/$id');
  }

  // ======================== HEALTH RECORDS ========================

  Future<List<dynamic>> getHealthRecords({
    String? memberName,
    String? recordType,
  }) async {
    final params = <String, String>{};
    if (memberName != null) params['memberName'] = memberName;
    if (recordType != null) params['recordType'] = recordType;
    return await _get(
      '/health-records',
      queryParams: params.isNotEmpty ? params : null,
    );
  }

  Future<List<dynamic>> getUpcomingVisits() async {
    return await _get('/health-records/upcoming-visits');
  }

  Future<List<dynamic>> getHealthRecordsByMember(String memberName) async {
    return await _get('/health-records/member/$memberName');
  }

  Future<dynamic> createHealthRecord(Map<String, dynamic> data) async {
    return await _post('/health-records', data);
  }

  Future<dynamic> updateHealthRecord(
    String id,
    Map<String, dynamic> data,
  ) async {
    return await _put('/health-records/$id', data);
  }

  Future<void> deleteHealthRecord(String id) async {
    await _delete('/health-records/$id');
  }
}

/// Custom API Exception
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
