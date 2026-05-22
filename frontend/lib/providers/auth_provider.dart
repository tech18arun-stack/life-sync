// ignore_for_file: library_prefixes

import 'package:flutter/foundation.dart';
import '../models/user.dart' as AppUser;
import '../services/auth_service.dart';

/// Authentication Provider for state management
///
/// Updated for Appwrite authentication flow.
class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  // Getters
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _authService.isLoggedIn;
  AppUser.User? get currentUser => _authService.currentUser;
  String? get token => _authService.token;
  String? get error => _error;
  bool get isAdmin => _authService.isAdmin;
  bool get isClient => _authService.isClient;

  /// Initialize auth state
  Future<bool> initialize() async {
    if (_isInitialized) return isLoggedIn;

    _isLoading = true;
    notifyListeners();

    final result = await _authService.initialize();

    _isLoading = false;
    _isInitialized = true;
    notifyListeners();

    return result;
  }

  /// Register new user
  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.register(
      name: name,
      email: email,
      password: password,
      phone: phone,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Login user
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }


  /// Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authService.logout();

    _isLoading = false;
    _isInitialized = false; // Reset so initialize() works after re-login
    notifyListeners();
  }

  /// Refresh current user profile from database (used after premium upgrade)
  Future<void> refreshUser() async {
    await _authService.refreshCurrentUser();
    notifyListeners();
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.updateProfile(
      name: name,
      phone: phone,
      avatar: avatar,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.changePassword(
      newPassword: newPassword,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Request password reset
  Future<bool> resetPassword(String email) async {
    _error = null;
    notifyListeners();

    final result = await _authService.resetPassword(email);

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Create family member user (CLIENT)
  Future<bool> createFamilyMemberUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? relation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await _authService.createFamilyMemberUser(
      name: name,
      email: email,
      password: password,
      phone: phone,
      relation: relation,
    );

    _isLoading = false;

    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }

  /// Get all family member users
  Future<List<AppUser.User>> getFamilyMemberUsers() async {
    return _authService.getFamilyMemberUsers();
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Upgrade current user to premium
  Future<bool> upgradeToPremium({int days = 30, String planType = 'premium'}) async {
    _isLoading = true;
    notifyListeners();

    final result = await _authService.upgradeToPremium(days: days, planType: planType);

    _isLoading = false;
    if (result['success']) {
      notifyListeners();
      return true;
    } else {
      _error = result['error'];
      notifyListeners();
      return false;
    }
  }
}
