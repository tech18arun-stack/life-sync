import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as AppUser;

/// Authentication Service for user login/register using Supabase
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _token;
  AppUser.User? _currentUser;

  // Getters
  String? get token => _token;
  AppUser.User? get currentUser => _currentUser;
  bool get isLoggedIn => _token != null && _currentUser != null;
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isClient => _currentUser?.isClient ?? false;

  // Get Supabase client
  SupabaseClient get client => Supabase.instance.client;

  /// Initialize auth service - check for stored token
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString(_tokenKey);
      final userJson = prefs.getString(_userKey);

      if (_token != null && userJson != null) {
        _currentUser = AppUser.User.fromJson(jsonDecode(userJson));

        // Check if user session is still valid
        final session = client.auth.currentSession;
        if (session != null) {
          // Refresh user profile from database
          await _loadUserProfile();
          return true;
        } else {
          await logout();
          return false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      return false;
    }
  }

  /// Register new user (creates ADMIN user)
  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {'name': name, 'phone': phone},
        emailRedirectTo: _getAppDeepLinkScheme(),
      );

      final user = response.user;
      if (user != null) {
        _token = response.session?.accessToken;

        // Create user profile as ADMIN
        _currentUser = AppUser.User(
          id: user.id,
          name: name,
          email: user.email ?? '',
          phone: phone ?? '',
          userType: 'admin', // Users registering directly are ADMIN
          role: 'owner',
          createdAt: DateTime.now(),
        );

        // Only save auth data if session exists (auto-confirm enabled in Supabase)
        if (_token != null) {
          await _createUserProfile(_currentUser!);
          await _saveAuthData();
        }

        return {
          'success': true,
          'user': _currentUser,
          'requiresConfirmation': response.session == null,
        };
      } else {
        return {'success': false, 'error': 'Registration failed'};
      }
    } catch (e) {
      debugPrint('Error registering: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        _token = response.session?.accessToken;

        // Load user profile from database to get user type
        await _loadUserProfile();

        if (_currentUser == null) {
          // If no profile exists, create one (legacy user or first login)
          _currentUser = AppUser.User(
            id: user.id,
            name: user.userMetadata?['name'] ?? '',
            email: user.email ?? '',
            phone: user.userMetadata?['phone'] ?? '',
            userType: 'admin', // Default to admin for existing users
            role: 'owner',
            createdAt: DateTime.now(),
          );
          await _createUserProfile(_currentUser!);
        }

        // Update last login
        await _updateLastLogin();
        await _saveAuthData();

        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': 'Login failed'};
      }
    } catch (e) {
      debugPrint('Error logging in: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      debugPrint('Error during logout: $e');
    }

    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Create user profile in database
  Future<void> _createUserProfile(AppUser.User user) async {
    try {
      await client.from('user_profiles').upsert({
        'id': user.id,
        'name': user.name,
        'email': user.email,
        'phone': user.phone,
        'avatar': user.avatar,
        'user_type': user.userType,
        'role': user.role,
        'parent_user_id': user.parentUserId,
        'family_id': user.familyId,
        'relation': user.relation,
        'is_active': user.isActive,
      });
    } catch (e) {
      debugPrint('Error creating user profile: $e');
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        _currentUser = AppUser.User.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin() async {
    try {
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      await client
          .from('user_profiles')
          .update({'last_login': DateTime.now().toIso8601String()})
          .eq('id', userId);
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatar != null) updates['avatar'] = avatar;

      // Update Supabase auth metadata
      final response = await client.auth.updateUser(
        UserAttributes(data: updates),
      );

      // Also update user_profiles table
      final userId = client.auth.currentUser?.id;
      if (userId != null) {
        await client.from('user_profiles').update(updates).eq('id', userId);
      }

      final user = response.user;
      if (user != null) {
        _currentUser = _currentUser?.copyWith(
          name: name ?? _currentUser?.name,
          phone: phone ?? _currentUser?.phone,
          avatar: avatar ?? _currentUser?.avatar,
        );
        await _saveAuthData();
        return {'success': true, 'user': _currentUser};
      } else {
        return {'success': false, 'error': 'Update failed'};
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await client.auth.updateUser(UserAttributes(password: newPassword));
      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Helper method to get the app's deep link scheme
  String _getAppDeepLinkScheme() {
    return 'lifesync://login-callback';
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

  // ===== FAMILY MEMBER (CLIENT) USER MANAGEMENT =====

  /// Create a family member with login credentials (CLIENT user)
  /// Only ADMIN users can create CLIENT users
  Future<Map<String, dynamic>> createFamilyMemberUser({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? relation,
  }) async {
    // Check if current user is admin
    if (!isAdmin) {
      return {
        'success': false,
        'error': 'Only admin users can create family member accounts',
      };
    }

    try {
      // First, we need to use Supabase Admin API or Edge Functions
      // For now, we'll create the user through the normal signup flow
      // but mark them as a client user in the profile

      final adminId = _currentUser?.id;
      final familyId =
          _currentUser?.familyId ??
          adminId; // Use admin's ID as family ID if none exists

      // Create the auth user (they'll need to confirm email separately)
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'phone': phone,
          'user_type': 'client',
          'parent_user_id': adminId,
        },
      );

      final newUser = response.user;
      if (newUser != null) {
        // Create user profile as CLIENT
        final clientProfile = AppUser.User(
          id: newUser.id,
          name: name,
          email: email,
          phone: phone,
          userType: 'client', // This is a CLIENT user
          role: 'member',
          parentUserId: adminId, // Link to the admin who created them
          familyId: familyId,
          relation: relation,
          createdAt: DateTime.now(),
        );

        // Insert profile into database
        await client.from('user_profiles').insert({
          'id': newUser.id,
          'name': name,
          'email': email,
          'phone': phone,
          'user_type': 'client',
          'role': 'member',
          'parent_user_id': adminId,
          'family_id': familyId,
          'relation': relation,
          'is_active': true,
        });

        // Update admin's family_id if not set
        if (_currentUser?.familyId == null) {
          await client
              .from('user_profiles')
              .update({'family_id': familyId})
              .eq('id', adminId!);
          _currentUser = _currentUser?.copyWith(familyId: familyId);
          await _saveAuthData();
        }

        return {
          'success': true,
          'user': clientProfile,
          'message':
              'Family member account created. They will need to verify their email.',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to create family member account',
        };
      }
    } catch (e) {
      debugPrint('Error creating family member user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Get all family member (client) users created by this admin
  Future<List<AppUser.User>> getFamilyMemberUsers() async {
    if (!isAdmin) return [];

    try {
      final adminId = _currentUser?.id;
      if (adminId == null) return [];

      final response = await client
          .from('user_profiles')
          .select()
          .eq('parent_user_id', adminId)
          .eq('user_type', 'client');

      return (response as List)
          .map((json) => AppUser.User.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting family member users: $e');
      return [];
    }
  }

  /// Update family member user profile
  Future<Map<String, dynamic>> updateFamilyMemberUser({
    required String memberId,
    String? name,
    String? phone,
    String? relation,
    bool? isActive,
  }) async {
    if (!isAdmin) {
      return {
        'success': false,
        'error': 'Only admin users can update family member accounts',
      };
    }

    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (relation != null) updates['relation'] = relation;
      if (isActive != null) updates['is_active'] = isActive;

      await client
          .from('user_profiles')
          .update(updates)
          .eq('id', memberId)
          .eq('parent_user_id', _currentUser?.id ?? '');

      return {'success': true, 'message': 'Family member updated successfully'};
    } catch (e) {
      debugPrint('Error updating family member user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Deactivate/activate a family member user account
  Future<Map<String, dynamic>> toggleFamilyMemberStatus(
    String memberId,
    bool isActive,
  ) async {
    return updateFamilyMemberUser(memberId: memberId, isActive: isActive);
  }

  /// Delete family member user (soft delete by deactivating)
  Future<Map<String, dynamic>> deleteFamilyMemberUser(String memberId) async {
    if (!isAdmin) {
      return {
        'success': false,
        'error': 'Only admin users can delete family member accounts',
      };
    }

    try {
      // Soft delete by deactivating the account
      await client
          .from('user_profiles')
          .update({'is_active': false})
          .eq('id', memberId)
          .eq('parent_user_id', _currentUser?.id ?? '');

      return {'success': true, 'message': 'Family member account deactivated'};
    } catch (e) {
      debugPrint('Error deleting family member user: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Request password reset for a family member
  Future<Map<String, dynamic>> resetFamilyMemberPassword({
    required String memberEmail,
  }) async {
    if (!isAdmin) {
      return {
        'success': false,
        'error': 'Only admin users can reset family member passwords',
      };
    }

    try {
      await client.auth.resetPasswordForEmail(
        memberEmail,
        redirectTo: _getAppDeepLinkScheme(),
      );
      return {
        'success': true,
        'message': 'Password reset email sent to $memberEmail',
      };
    } catch (e) {
      debugPrint('Error resetting family member password: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
