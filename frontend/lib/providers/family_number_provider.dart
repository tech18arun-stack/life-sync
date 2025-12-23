import 'package:flutter/foundation.dart';
import '../models/family_number.dart';
import '../services/api_service.dart';

/// Provider for managing family phone numbers via MongoDB
class FamilyNumberProvider with ChangeNotifier {
  final ApiService _api = ApiService();

  List<FamilyNumber> _numbers = [];
  bool _isLoading = false;
  String? _error;

  List<FamilyNumber> get numbers => _numbers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered lists
  List<FamilyNumber> get emergencyNumbers =>
      _numbers.where((n) => n.isEmergency).toList();
  List<FamilyNumber> get familyNumbers =>
      _numbers.where((n) => n.category == 'Family').toList();
  List<FamilyNumber> get doctorNumbers =>
      _numbers.where((n) => n.category == 'Doctor').toList();
  List<FamilyNumber> get workNumbers =>
      _numbers.where((n) => n.category == 'Work').toList();

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getFamilyNumbers();
      _numbers = data.map((n) => FamilyNumber.fromJson(n)).toList();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading family numbers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNumber(FamilyNumber number) async {
    try {
      final response = await _api.createFamilyNumber(number.toJson());
      final newNumber = FamilyNumber.fromJson(response);
      _numbers.add(newNumber);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding family number: $e');
      rethrow;
    }
  }

  Future<void> updateNumber(FamilyNumber number) async {
    try {
      final response = await _api.updateFamilyNumber(
        number.id!,
        number.toJson(),
      );
      final updatedNumber = FamilyNumber.fromJson(response);
      final index = _numbers.indexWhere((n) => n.id == number.id);
      if (index != -1) {
        _numbers[index] = updatedNumber;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating family number: $e');
      rethrow;
    }
  }

  Future<void> deleteNumber(String id) async {
    try {
      await _api.deleteFamilyNumber(id);
      _numbers.removeWhere((n) => n.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting family number: $e');
      rethrow;
    }
  }

  List<FamilyNumber> getNumbersByCategory(String category) {
    return _numbers.where((n) => n.category == category).toList();
  }

  FamilyNumber? getPrimaryNumber() {
    try {
      return _numbers.firstWhere((n) => n.isPrimary);
    } catch (e) {
      return null;
    }
  }

  int get totalCount => _numbers.length;
  int get emergencyCount => emergencyNumbers.length;
}
