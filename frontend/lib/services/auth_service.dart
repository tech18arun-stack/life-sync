import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';

/// Authentication Service for user login/register
class AuthService {
  // static const String _baseUrl = 'http://localhost:3001/api/auth'; // Local development
  static const String _baseUrl =
      'https://life-sync.onrender.com/api/auth'; // Production (Render)
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  User? _currentUser;

  // Getters
  String? get token => _token;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _currentUser != null;

  // Headers with auth token
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Initialize auth service - check for stored token
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (_token != null && userJson != null) {
        _currentUser = User.fromJson(jsonDecode(userJson));

        // Verify token is still valid
        final isValid = await verifyToken();
        if (!isValid) {
          await logout();
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      return false;
    }
  }

  /// Verify current token is valid
  Future<bool> verifyToken() async {
    if (_token == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/me'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(jsonDecode(response.body));
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error verifying token: $e');
      return false;
    }
  }

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        await _saveAuthData();
        return {'success': true, 'user': _currentUser};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);
        await _saveAuthData();
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Login failed'};
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      if (_token != null) {
        await http.post(Uri.parse('$_baseUrl/logout'), headers: _headers);
      }
    } catch (e) {
      debugPrint('Error during logout API call: $e');
    }

    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/me'),
        headers: _headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (avatar != null) 'avatar': avatar,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(data);
        await _saveAuthData();
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': data['error'] ?? 'Update failed'};
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/change-password'),
        headers: _headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Password change failed',
        };
      }
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  // ===== FAMILY MEMBER USER MANAGEMENT =====

  /// Create a family member with login credentials
  Future<Map<String, dynamic>> createFamilyMemberUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? relation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/family-members'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
          if (relation != null) 'relation': relation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true,
          'familyMember': User.fromJson(data['familyMember']),
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to create family member',
        };
      }
    } catch (e) {
      debugPrint('Error creating family member user: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Get all family member users
  Future<List<User>> getFamilyMemberUsers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/family-members'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => User.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting family member users: $e');
      return [];
    }
  }

  /// Update family member user
  Future<Map<String, dynamic>> updateFamilyMemberUser({
    required String memberId,
    String? name,
    String? phone,
    String? relation,
    bool? isActive,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/family-members/$memberId'),
        headers: _headers,
        body: jsonEncode({
          if (name != null) 'name': name,
          if (phone != null) 'phone': phone,
          if (relation != null) 'relation': relation,
          if (isActive != null) 'isActive': isActive,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'user': User.fromJson(data)};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to update family member',
        };
      }
    } catch (e) {
      debugPrint('Error updating family member user: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Delete family member user
  Future<Map<String, dynamic>> deleteFamilyMemberUser(String memberId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/family-members/$memberId'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to delete family member',
        };
      }
    } catch (e) {
      debugPrint('Error deleting family member user: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  /// Reset family member password
  Future<Map<String, dynamic>> resetFamilyMemberPassword({
    required String memberId,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/family-members/$memberId/reset-password'),
        headers: _headers,
        body: jsonEncode({'newPassword': newPassword}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'error': data['error'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      debugPrint('Error resetting family member password: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }
}
