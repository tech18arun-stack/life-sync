import 'package:flutter/foundation.dart';
import '../models/family_number.dart';
import '../repositories/all_repositories.dart';

/// Provider for managing family phone numbers via Appwrite
/// 
/// Updated to use Appwrite backend via FamilyNumbersRepository.
class FamilyNumberProvider with ChangeNotifier {
  final FamilyNumbersRepository _repository = FamilyNumbersRepository();

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
      _numbers = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading family numbers: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addNumber(FamilyNumber number) async {
    try {
      final newNumber = await _repository.create(number);
      _numbers.add(newNumber);
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding family number: $e');
      rethrow;
    }
  }

  Future<void> updateNumber(FamilyNumber number) async {
    try {
      final updatedNumber = await _repository.update(number.id!, number);
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
      await _repository.delete(id);
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
