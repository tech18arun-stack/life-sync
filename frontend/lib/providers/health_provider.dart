import 'package:flutter/foundation.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';

class HealthProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  List<HealthRecord> _healthRecords = [];
  bool _isLoading = false;
  String? _error;

  List<HealthRecord> get healthRecords => _healthRecords;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getHealthRecords();
      _healthRecords = data.map((r) => HealthRecord.fromJson(r)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading health records: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  Future<void> addHealthRecord(HealthRecord record) async {
    try {
      final response = await _api.createHealthRecord(record.toJson());
      final newRecord = HealthRecord.fromJson(response);
      _healthRecords.add(newRecord);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding health record: $e');
      rethrow;
    }
  }

  Future<void> updateHealthRecord(HealthRecord record) async {
    try {
      final response = await _api.updateHealthRecord(
        record.id!,
        record.toJson(),
      );
      final updatedRecord = HealthRecord.fromJson(response);
      final index = _healthRecords.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _healthRecords[index] = updatedRecord;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating health record: $e');
      rethrow;
    }
  }

  Future<void> deleteHealthRecord(String id) async {
    try {
      await _api.deleteHealthRecord(id);
      _healthRecords.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting health record: $e');
      rethrow;
    }
  }

  List<HealthRecord> getRecordsByMember(String memberName) {
    return _healthRecords.where((r) => r.memberName == memberName).toList();
  }

  List<HealthRecord> getRecordsByType(String type) {
    return _healthRecords.where((r) => r.recordType == type).toList();
  }

  List<HealthRecord> getUpcomingVisits() {
    final now = DateTime.now();
    return _healthRecords
        .where((r) => r.nextVisit != null && r.nextVisit!.isAfter(now))
        .toList()
      ..sort((a, b) => a.nextVisit!.compareTo(b.nextVisit!));
  }

  List<HealthRecord> getRecentRecords({int limit = 10}) {
    final sorted = List<HealthRecord>.from(_healthRecords);
    sorted.sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(limit).toList();
  }
}
