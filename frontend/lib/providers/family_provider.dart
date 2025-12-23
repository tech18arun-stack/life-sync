import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import '../services/api_service.dart';

class FamilyProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<FamilyMember> _members = [];
  bool _isLoading = false;
  String? _error;

  List<FamilyMember> get members => _members;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getFamilyMembers();
      _members = data.map((m) => FamilyMember.fromJson(m)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading family members: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  Future<void> addMember(FamilyMember member) async {
    try {
      final response = await _api.createFamilyMember(member.toJson());
      final newMember = FamilyMember.fromJson(response);
      _members.add(newMember);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding family member: $e');
      rethrow;
    }
  }

  Future<void> updateMember(FamilyMember member) async {
    try {
      final response = await _api.updateFamilyMember(
        member.id!,
        member.toJson(),
      );
      final updatedMember = FamilyMember.fromJson(response);
      final index = _members.indexWhere((m) => m.id == member.id);
      if (index != -1) {
        _members[index] = updatedMember;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating family member: $e');
      rethrow;
    }
  }

  Future<void> deleteMember(String id) async {
    try {
      await _api.deleteFamilyMember(id);
      _members.removeWhere((m) => m.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting family member: $e');
      rethrow;
    }
  }

  FamilyMember? getMemberById(String id) {
    try {
      return _members.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }

  FamilyMember? getMemberByName(String name) {
    try {
      return _members.firstWhere((m) => m.name == name);
    } catch (e) {
      return null;
    }
  }

  List<FamilyMember> getEmergencyContacts() {
    return _members.where((m) => m.isEmergencyContact).toList();
  }

  int get memberCount => _members.length;
}
