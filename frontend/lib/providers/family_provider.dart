import 'package:flutter/foundation.dart';
import '../models/family_member.dart';
import '../repositories/all_repositories.dart';

/// Family Provider - State management for family members
/// 
/// Updated to use Appwrite backend via FamilyMembersRepository.
class FamilyProvider with ChangeNotifier {
  final FamilyMembersRepository _repository = FamilyMembersRepository();

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
      _members = await _repository.getAll();
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
      final newMember = await _repository.create(member);
      _members.add(newMember);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding family member: $e');
      rethrow;
    }
  }

  Future<void> updateMember(FamilyMember member) async {
    try {
      final updatedMember = await _repository.update(member.id!, member);
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
      await _repository.delete(id);
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
