import 'dart:convert';
import 'package:appwrite/appwrite.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart' as AppUser;
import 'appwrite_service.dart';

/// Authentication Service for user login/register using Appwrite
/// 
/// This service replaces the Supabase authentication with Appwrite Auth.
/// 
/// User roles:
/// - Owner: Full access
/// - Member: Family member access
/// - Client: Limited access (created by Admin)
class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final AppwriteService _appwrite = AppwriteService();
  
  String? _token;
  AppUser.User? _currentUser;

  // Getters
  String? get token => _token;
  AppUser.User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.userType == 'admin';
  bool get isClient => _currentUser?.userType == 'client';

  /// Initialize auth service - check for stored user data
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);

      if (userJson != null) {
        // Load user data from storage
        _currentUser = AppUser.User.fromJson(jsonDecode(userJson));
        
        debugPrint('✅ Found stored user: ${_currentUser?.email} (ID: ${_currentUser?.id})');

        // Verify session is still valid with Appwrite
        try {
          final session = await _appwrite.account.getSession(sessionId: 'current');
          debugPrint('✅ Session valid: ${session.$id}');
          
          // Refresh user profile from database
          await _loadUserProfile();
          debugPrint('✅ User profile refreshed');
          return true;
        } catch (e) {
          // Session invalid or expired
          debugPrint('⚠️ Session invalid or expired: $e');
          // Don't logout automatically - let the app decide
          _currentUser = null;
          await prefs.remove(_userKey);
          return false;
        }
      }
      
      debugPrint('ℹ️ No stored user data found');
      return false;
    } catch (e) {
      debugPrint('❌ Error initializing auth: $e');
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
      debugPrint('📝 Attempting registration for: $email');
      
      // Create Appwrite account
      final user = await _appwrite.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );
      debugPrint('✅ Appwrite account created: ${user.email} (ID: ${user.$id})');

      // Create session immediately
      final session = await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      debugPrint('✅ Session created: ${session.$id}');

      // Create user profile as ADMIN
      _currentUser = AppUser.User(
        id: user.$id,
        name: name,
        email: user.email ?? '',
        phone: phone ?? '',
        userType: 'admin', // Users registering directly are ADMIN
        role: 'owner',
        createdAt: DateTime.now(),
      );

      // Create user profile in database
      await _createUserProfile(_currentUser!);
      debugPrint('✅ User profile created in database');
      
      // Save user data to local storage
      await _saveAuthData();
      debugPrint('✅ User data saved to local storage');

      return {
        'success': true,
        'user': _currentUser,
        'requiresConfirmation': false, // Appwrite doesn't require email confirmation by default
      };
    } catch (e) {
      debugPrint('❌ Error registering: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Attempting login for: $email');
      
      // Create email password session
      await _appwrite.account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      debugPrint('✅ Session created');

      // Get current user
      final user = await _appwrite.account.get();
      debugPrint('✅ Appwrite user: ${user.email} (ID: ${user.$id})');

      // Load user profile from database to get user type
      await _loadUserProfile();

      if (_currentUser == null) {
        // If no profile exists, create one (first login or legacy user)
        _currentUser = AppUser.User(
          id: user.$id,
          name: user.name ?? '',
          email: user.email ?? '',
          phone: user.phone ?? '',
          userType: 'admin', // Default to admin for existing users
          role: 'owner',
          createdAt: DateTime.now(),
        );
        await _createUserProfile(_currentUser!);
        debugPrint('✅ Created user profile in database');
      } else {
        debugPrint('✅ Loaded existing user profile: ${_currentUser?.email}');
      }

      // Update last login
      await _updateLastLogin();
      
      // Save user data to local storage
      await _saveAuthData();
      debugPrint('✅ User data saved to local storage');

      return {'success': true, 'user': _currentUser};
    } catch (e) {
      debugPrint('❌ Error logging in: $e');
      return {
        'success': false,
        'error': _getErrorMessage(e),
      };
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      // Delete current session
      await _appwrite.account.deleteSession(sessionId: 'current');
    } catch (e) {
      debugPrint('Error during logout: $e');
    }

    // Delete all sessions (optional - uncomment if you want to logout from all devices)
    // await _appwrite.account.deleteSessions();

    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// Create user profile in database
  Future<void> _createUserProfile(AppUser.User user) async {
    try {
      await _appwrite.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: user.id!,
        data: {
          'id': user.id,
          'name': user.name ?? '',
          'email': user.email ?? '',
          'phone': user.phone ?? '',
          'avatar': user.avatar ?? '',
          'user_type': user.userType,
          'role': user.role,
          'parent_user_id': user.parentUserId ?? '',
          'family_id': user.familyId ?? '',
          'relation': user.relation ?? '',
          'is_active': user.isActive,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.id!)),
          Permission.update(Role.user(user.id!)),
          Permission.delete(Role.user(user.id!)),
        ],
      );
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      // Profile might already exist, try update instead
      await _updateUserProfileInDb(user.id!, {
        'name': user.name ?? '',
        'email': user.email ?? '',
        'phone': user.phone ?? '',
        'avatar': user.avatar ?? '',
        'user_type': user.userType,
        'role': user.role,
      });
    }
  }

  /// Load user profile from database
  Future<void> _loadUserProfile() async {
    try {
      final userId = _appwrite.currentUserId;
      if (userId == null) return;

      final document = await _appwrite.databases.getDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: userId,
      );

      _currentUser = AppUser.User.fromJson({...document.data, 'id': document.$id});
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  /// Update last login timestamp
  Future<void> _updateLastLogin() async {
    try {
      final userId = _appwrite.currentUserId;
      if (userId == null) return;

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: userId,
        data: {
          'last_login': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  /// Update user profile in database
  Future<void> _updateUserProfileInDb(String userId, Map<String, dynamic> data) async {
    try {
      data['updated_at'] = DateTime.now().toIso8601String();
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: userId,
        data: data,
      );
    } catch (e) {
      debugPrint('Error updating user profile in DB: $e');
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? avatar,
  }) async {
    try {
      final userId = _appwrite.currentUserId;
      if (userId == null) {
        return {'success': false, 'error': 'User not logged in'};
      }

      // Update Appwrite account
      if (name != null) {
        await _appwrite.account.updateName(name: name);
      }

      // Update user_profiles table
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatar != null) updates['avatar'] = avatar;
      
      await _updateUserProfileInDb(userId, updates);

      // Update local user object
      _currentUser = _currentUser?.copyWith(
        name: name ?? _currentUser?.name,
        phone: phone ?? _currentUser?.phone,
        avatar: avatar ?? _currentUser?.avatar,
      );
      await _saveAuthData();

      return {'success': true, 'user': _currentUser};
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String newPassword,
  }) async {
    try {
      await _appwrite.account.updatePassword(
        password: newPassword,
        oldPassword: null, // Appwrite doesn't require old password by default
      );
      return {'success': true, 'message': 'Password changed successfully'};
    } catch (e) {
      debugPrint('Error changing password: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Request password reset
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      // Get the app's origin URL for password reset redirect
      final origin = 'lifesync://'; // Deep link scheme
      
      await _appwrite.account.createRecovery(
        email: email,
        url: origin,
      );
      return {
        'success': true,
        'message': 'Password reset email sent to $email',
      };
    } catch (e) {
      debugPrint('Error resetting password: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Helper method to get error messages
  String _getErrorMessage(dynamic error) {
    if (error is AppwriteException) {
      switch (error.code) {
        case 401:
          return 'Invalid email or password';
        case 404:
          return 'User not found';
        case 409:
          return 'Email already in use';
        case 429:
          return 'Too many attempts. Please try again later';
        default:
          return error.message ?? 'An error occurred';
      }
    }
    return error.toString();
  }

  /// Save auth data to local storage
  Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    // Note: Appwrite manages sessions internally, we just save user data
    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  // ============================================================================
  // FAMILY MEMBER (CLIENT) USER MANAGEMENT
  // ============================================================================

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
      final adminId = _currentUser?.id;
      final familyId =
          _currentUser?.familyId ??
          adminId; // Use admin's ID as family ID if none exists

      // Create the auth user
      final user = await _appwrite.account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Create user profile as CLIENT
      final clientProfile = AppUser.User(
        id: user.$id,
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
      await _appwrite.databases.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: user.$id,
        data: {
          'id': user.$id,
          'name': name,
          'email': email,
          'phone': phone ?? '',
          'user_type': 'client',
          'role': 'member',
          'parent_user_id': adminId,
          'family_id': familyId,
          'relation': relation ?? '',
          'is_active': true,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.user(user.$id)),
          Permission.update(Role.user(user.$id)),
          Permission.delete(Role.user(user.$id)),
        ],
      );

      // Update admin's family_id if not set
      if (_currentUser?.familyId == null) {
        await _appwrite.databases.updateDocument(
          databaseId: AppwriteService.databaseId,
          collectionId: AppwriteService.userProfilesCollection,
          documentId: adminId!,
          data: {'family_id': familyId},
        );
        _currentUser = _currentUser?.copyWith(familyId: familyId);
        await _saveAuthData();
      }

      return {
        'success': true,
        'user': clientProfile,
        'message': 'Family member account created successfully',
      };
    } catch (e) {
      debugPrint('Error creating family member user: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Get all family member (client) users created by this admin
  Future<List<AppUser.User>> getFamilyMemberUsers() async {
    if (!isAdmin) return [];

    try {
      final adminId = _currentUser?.id;
      if (adminId == null) return [];

      final documentList = await _appwrite.databases.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        queries: [
          'parent_user_id="$adminId"',
          'user_type="client"',
        ],
      );

      return documentList.documents
          .map((doc) => AppUser.User.fromJson({...doc.data, 'id': doc.$id}))
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

      await _appwrite.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: memberId,
        data: updates,
      );

      return {'success': true, 'message': 'Family member updated successfully'};
    } catch (e) {
      debugPrint('Error updating family member user: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
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
      await _appwrite.databases.updateDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.userProfilesCollection,
        documentId: memberId,
        data: {'is_active': false},
      );

      return {
        'success': true,
        'message': 'Family member account deactivated',
      };
    } catch (e) {
      debugPrint('Error deleting family member user: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
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
      await resetPassword(memberEmail);
      return {
        'success': true,
        'message': 'Password reset email sent to $memberEmail',
      };
    } catch (e) {
      debugPrint('Error resetting family member password: $e');
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  /// Get current session
  Future<Map<String, dynamic>?> getCurrentSession() async {
    try {
      final session = await _appwrite.account.getSession(sessionId: 'current');
      // Return session properties as a map
      return {
        'userId': session.userId,
        'provider': session.provider,
        'expire': session.expire,
      };
    } catch (e) {
      return null;
    }
  }

  /// Get all active sessions
  Future<List<Map<String, dynamic>>> getSessions() async {
    try {
      final sessions = await _appwrite.account.listSessions();
      return sessions.sessions.map((s) => {
        'userId': s.userId,
        'provider': s.provider,
        'expire': s.expire,
      }).toList();
    } catch (e) {
      debugPrint('Error getting sessions: $e');
      return [];
    }
  }

  /// Delete a specific session
  Future<void> deleteSession(String sessionId) async {
    try {
      await _appwrite.account.deleteSession(sessionId: sessionId);
    } catch (e) {
      debugPrint('Error deleting session: $e');
      rethrow;
    }
  }
}
