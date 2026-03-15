import 'package:flutter/foundation.dart';
import '../models/health_record.dart';
import '../repositories/all_repositories.dart';
import '../services/storage_service.dart';

/// Health Provider - State management for health records
/// 
/// Updated to use Appwrite backend via HealthRecordsRepository.
class HealthProvider with ChangeNotifier {
  final HealthRecordsRepository _repository = HealthRecordsRepository();
  final StorageService _storageService = StorageService();
  
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
      _healthRecords = await _repository.getAll();
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
      final newRecord = await _repository.create(record);
      _healthRecords.add(newRecord);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding health record: $e');
      rethrow;
    }
  }

  Future<void> updateHealthRecord(HealthRecord record) async {
    try {
      final updatedRecord = await _repository.update(record.id!, record);
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
      await _repository.delete(id);
      _healthRecords.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting health record: $e');
      rethrow;
    }
  }

  /// Upload image for health record
  Future<Map<String, dynamic>?> uploadHealthImage(String filePath) async {
    try {
      return await _storageService.uploadFile(filePath: filePath);
    } catch (e) {
      debugPrint('Error uploading health image: $e');
      return null;
    }
  }

  /// Add attachments to health record
  Future<void> addAttachments(String recordId, List<String> attachmentUrls) async {
    try {
      await _repository.addAttachments(recordId, attachmentUrls);
      // Refresh the record
      await initialize();
    } catch (e) {
      debugPrint('Error adding attachments: $e');
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
