import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'config_service.dart';

/// Appwrite Service - Main client initialization and configuration
///
/// This service handles the connection to your self-hosted Appwrite instance.
///
/// Configuration via --dart-define:
/// - APPWRITE_ENDPOINT: API endpoint URL
/// - APPWRITE_PROJECT_ID: Project ID
/// - APPWRITE_DATABASE_ID: Database ID
/// - APPWRITE_HEALTH_IMAGES_BUCKET: Storage bucket ID
class AppwriteService {
  static final AppwriteService _instance = AppwriteService._internal();
  factory AppwriteService() => _instance;
  AppwriteService._internal();

  late Client _client;
  late Account _account;
  late Databases _databases;
  late Storage _storage;

  User? _cachedUser;

  // Configuration from --dart-define
  static const String endpoint = String.fromEnvironment(
    'APPWRITE_ENDPOINT',
    defaultValue: 'https://api.websitescorp.com/v1',
  );
  static const String projectId = String.fromEnvironment(
    'APPWRITE_PROJECT_ID',
    defaultValue: '69e45bf20039aebb88ac',
  );
  static const String databaseId = String.fromEnvironment(
    'APPWRITE_DATABASE_ID',
    defaultValue: '69e45c7d001156126993',
  );

  // Collection IDs
  static const String userProfilesCollection = 'user_profiles';
  static const String expensesCollection = 'expenses';
  static const String incomesCollection = 'incomes';
  static const String budgetsCollection = 'budgets';
  static const String familyMembersCollection = 'family_members';
  static const String familyNumbersCollection = 'family_numbers';
  static const String tasksCollection = 'tasks';
  static const String savingsGoalsCollection = 'savings_goals';
  static const String remindersCollection = 'reminders';

  static const String subscriptionsCollection = 'subscriptions';

  /// Initialize Appwrite client
  Future<void> initialize() async {
    try {
      final dynamicEndpoint = ConfigService().apiBaseUrl;

      _client = Client()
          .setEndpoint(dynamicEndpoint)
          .setProject(projectId)
          .setSelfSigned(status: false); // ✅ Production SSL (Certbot installed)

      _account = Account(_client);
      _databases = Databases(_client);
      _storage = Storage(_client);

      debugPrint('✅ Appwrite initialized successfully');
      debugPrint('Endpoint: $dynamicEndpoint');
      debugPrint('Project ID: $projectId');
      debugPrint('Database: $databaseId');
    } catch (e) {
      debugPrint('❌ Appwrite initialization error: $e');
      rethrow;
    }
  }

  // Getters
  Client get client => _client;
  Account get account => _account;
  Databases get databases => _databases;
  Storage get storage => _storage;

  /// Get current user ID (async - fetches from Appwrite)
  /// This ensures we always have the latest ID after OAuth login
  Future<String?> getCurrentUserId() async {
    try {
      // Try cached user first
      if (_cachedUser != null) {
        return _cachedUser!.$id;
      }

      // Fetch from Appwrite if cache is empty
      final user = await _account.get();
      _cachedUser = user;
      return user.$id;
    } catch (e) {
      debugPrint('⚠️ Failed to get current user ID: $e');
      return null;
    }
  }

  /// Get cached user ID (sync, may be null after OAuth)
  /// Prefer getCurrentUserId() for reliable results
  String? get currentUserId {
    return _cachedUser?.$id;
  }

  /// Refresh cached user data from Appwrite
  Future<void> _refreshUser() async {
    try {
      _cachedUser = await _account.get();
      debugPrint('✅ User cache refreshed: ${_cachedUser?.email}');
    } catch (e) {
      debugPrint('⚠️ Failed to refresh user cache: $e');
      _cachedUser = null;
    }
  }

  /// Check if user is logged in (async - verifies with Appwrite)
  Future<bool> checkIsLoggedIn() async {
    try {
      await _account.get();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is logged in (sync - uses cache, may be stale after OAuth)
  /// Prefer checkIsLoggedIn() for reliable results
  bool get isLoggedIn => currentUserId != null;

  // ============================================================================
  // GENERIC CRUD METHODS
  // ============================================================================

  /// Create a document in a collection
  Future<Map<String, dynamic>> createDocument({
    required String collectionId,
    required Map<String, dynamic> data,
    List<String>? permissions,
  }) async {
    try {
      // Refresh user data to get current user ID
      await _refreshUser();

      // Ensure 'id' is not in data payloads since it's not a schema attribute in Appwrite
      if (data.containsKey('id')) {
        data.remove('id');
      }

      // Add user_id if not present (use async method for reliability)
      final userId = currentUserId ?? await getCurrentUserId();
      if (userId != null && !data.containsKey('user_id')) {
        data['user_id'] = userId;
      }

      // Add timestamps
      final now = DateTime.now().toIso8601String();
      if (!data.containsKey('created_at')) {
        data['created_at'] = now;
      }
      data['updated_at'] = now;

      final document = await _databases.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: data,
        permissions:
            permissions ??
            (userId != null
                ? [
                    Permission.read(Role.user(userId)),
                    Permission.update(Role.user(userId)),
                    Permission.delete(Role.user(userId)),
                  ]
                : null),
      );

      return _documentToMap(document);
    } catch (e) {
      debugPrint('Error creating document in $collectionId: $e');
      rethrow;
    }
  }

  /// Helper method to convert Document to `Map<String, dynamic>`
  Map<String, dynamic> _documentToMap(Document doc) {
    return {...doc.data, 'id': doc.$id};
  }

  /// Get a list of documents from a collection
  Future<List<Map<String, dynamic>>> getDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    try {
      await _refreshUser();

      // Add user_id filter by default (use async method for reliability after OAuth)
      final userId = currentUserId ?? await getCurrentUserId();
      if (userId != null) {
        final userQuery = Query.equal('user_id', userId);
        queries = queries != null ? [...queries, userQuery] : [userQuery];
      }

      // Add a higher limit to prevent Appwrite's default 25-item pagination cutoff
      queries = queries != null
          ? [...queries, Query.limit(5000)]
          : [Query.limit(5000)];

      final documentList = await _databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: queries,
      );

      return documentList.documents.map(_documentToMap).toList();
    } catch (e) {
      debugPrint('Error getting documents from $collectionId: $e');
      rethrow;
    }
  }

  /// Get a single document by ID
  Future<Map<String, dynamic>?> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    try {
      final document = await _databases.getDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
      return _documentToMap(document);
    } catch (e) {
      debugPrint('Error getting document $documentId from $collectionId: $e');
      return null;
    }
  }

  /// Update a document
  Future<Map<String, dynamic>> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Ensure 'id' is not in data payloads since it's not a schema attribute
      if (data.containsKey('id')) {
        data.remove('id');
      }

      // Add updated_at timestamp
      data['updated_at'] = DateTime.now().toIso8601String();

      final document = await _databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: data,
      );

      return _documentToMap(document);
    } catch (e) {
      debugPrint('Error updating document $documentId in $collectionId: $e');
      rethrow;
    }
  }

  /// Delete a document
  Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    try {
      await _databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      debugPrint('Error deleting document $documentId from $collectionId: $e');
      rethrow;
    }
  }

  // ============================================================================
  // SPECIFIC COLLECTION METHODS
  // ============================================================================

  // ---------- User Profiles ----------
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final documents = await getDocuments(
        collectionId: userProfilesCollection,
        queries: [Query.equal('id', userId)],
      );
      return documents.isNotEmpty ? documents.first : null;
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> createUserProfile(
    Map<String, dynamic> data,
  ) async {
    return createDocument(collectionId: userProfilesCollection, data: data);
  }

  Future<Map<String, dynamic>> updateUserProfile(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: userProfilesCollection,
      documentId: id,
      data: data,
    );
  }

  Future<List<Map<String, dynamic>>> getClientUsers(String adminId) async {
    try {
      return await getDocuments(
        collectionId: userProfilesCollection,
        queries: [
          Query.equal('parent_user_id', adminId),
          Query.equal('user_type', 'client'),
        ],
      );
    } catch (e) {
      debugPrint('Error getting client users: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyUserProfiles(
    String familyId,
  ) async {
    try {
      return await getDocuments(
        collectionId: userProfilesCollection,
        queries: [Query.equal('family_id', familyId)],
      );
    } catch (e) {
      debugPrint('Error getting family user profiles: $e');
      return [];
    }
  }

  // ---------- Expenses ----------
  Future<List<Map<String, dynamic>>> getExpenses({String? category}) async {
    List<String> queries = [];
    if (category != null) {
      queries.add(Query.equal('category', category));
    }
    return getDocuments(collectionId: expensesCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createExpense(Map<String, dynamic> data) async {
    return createDocument(collectionId: expensesCollection, data: data);
  }

  Future<Map<String, dynamic>> updateExpense(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: expensesCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteExpense(String id) async {
    await deleteDocument(collectionId: expensesCollection, documentId: id);
  }

  // ---------- Incomes ----------
  Future<List<Map<String, dynamic>>> getIncomes({String? source}) async {
    List<String> queries = [];
    if (source != null) {
      queries.add(Query.equal('source', source));
    }
    return getDocuments(collectionId: incomesCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createIncome(Map<String, dynamic> data) async {
    return createDocument(collectionId: incomesCollection, data: data);
  }

  Future<Map<String, dynamic>> updateIncome(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: incomesCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteIncome(String id) async {
    await deleteDocument(collectionId: incomesCollection, documentId: id);
  }

  // ---------- Budgets ----------
  Future<List<Map<String, dynamic>>> getBudgets({int? month, int? year}) async {
    List<String> queries = [];
    if (month != null) {
      queries.add(Query.equal('month', month));
    }
    if (year != null) {
      queries.add(Query.equal('year', year));
    }
    return getDocuments(collectionId: budgetsCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createBudget(Map<String, dynamic> data) async {
    return createDocument(collectionId: budgetsCollection, data: data);
  }

  Future<Map<String, dynamic>> updateBudget(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: budgetsCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteBudget(String id) async {
    await deleteDocument(collectionId: budgetsCollection, documentId: id);
  }

  // ---------- Family Members ----------
  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    return getDocuments(collectionId: familyMembersCollection);
  }

  Future<Map<String, dynamic>> createFamilyMember(
    Map<String, dynamic> data,
  ) async {
    return createDocument(collectionId: familyMembersCollection, data: data);
  }

  Future<Map<String, dynamic>> updateFamilyMember(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: familyMembersCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteFamilyMember(String id) async {
    await deleteDocument(collectionId: familyMembersCollection, documentId: id);
  }

  // ---------- Family Numbers ----------
  Future<List<Map<String, dynamic>>> getFamilyNumbers({
    String? category,
    bool? isEmergency,
  }) async {
    List<String> queries = [];
    if (category != null) {
      queries.add(Query.equal('category', category));
    }
    if (isEmergency != null) {
      queries.add(Query.equal('is_emergency', isEmergency));
    }
    return getDocuments(
      collectionId: familyNumbersCollection,
      queries: queries,
    );
  }

  Future<Map<String, dynamic>> createFamilyNumber(
    Map<String, dynamic> data,
  ) async {
    return createDocument(collectionId: familyNumbersCollection, data: data);
  }

  Future<Map<String, dynamic>> updateFamilyNumber(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: familyNumbersCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteFamilyNumber(String id) async {
    await deleteDocument(collectionId: familyNumbersCollection, documentId: id);
  }

  // ---------- Tasks ----------
  Future<List<Map<String, dynamic>>> getTasks({
    String? status,
    String? priority,
    bool? isCompleted,
  }) async {
    List<String> queries = [];
    if (status != null) {
      queries.add(Query.equal('status', status));
    }
    if (priority != null) {
      queries.add(Query.equal('priority', priority));
    }
    if (isCompleted != null) {
      queries.add(Query.equal('is_completed', isCompleted));
    }
    return getDocuments(collectionId: tasksCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createTask(Map<String, dynamic> data) async {
    return createDocument(collectionId: tasksCollection, data: data);
  }

  Future<Map<String, dynamic>> updateTask(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: tasksCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteTask(String id) async {
    await deleteDocument(collectionId: tasksCollection, documentId: id);
  }

  // ---------- Savings Goals ----------
  Future<List<Map<String, dynamic>>> getSavingsGoals({
    String? category,
    bool? isCompleted,
  }) async {
    List<String> queries = [];
    if (category != null) {
      queries.add(Query.equal('category', category));
    }
    if (isCompleted != null) {
      queries.add(Query.equal('is_completed', isCompleted));
    }
    return getDocuments(collectionId: savingsGoalsCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createSavingsGoal(
    Map<String, dynamic> data,
  ) async {
    return createDocument(collectionId: savingsGoalsCollection, data: data);
  }

  Future<Map<String, dynamic>> updateSavingsGoal(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: savingsGoalsCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteSavingsGoal(String id) async {
    await deleteDocument(collectionId: savingsGoalsCollection, documentId: id);
  }

  // ---------- Reminders ----------
  Future<List<Map<String, dynamic>>> getReminders({
    bool? isPaid,
    String? type,
  }) async {
    List<String> queries = [];
    if (isPaid != null) {
      queries.add(Query.equal('is_paid', isPaid));
    }
    if (type != null) {
      queries.add(Query.equal('type', type));
    }
    return getDocuments(collectionId: remindersCollection, queries: queries);
  }

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> data) async {
    return createDocument(collectionId: remindersCollection, data: data);
  }

  Future<Map<String, dynamic>> updateReminder(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: remindersCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteReminder(String id) async {
    await deleteDocument(collectionId: remindersCollection, documentId: id);
  }

  // ---------- Subscriptions ----------
  Future<List<Map<String, dynamic>>> getSubscriptions() async {
    return getDocuments(collectionId: subscriptionsCollection);
  }

  Future<Map<String, dynamic>> createSubscription(
    Map<String, dynamic> data,
  ) async {
    return createDocument(collectionId: subscriptionsCollection, data: data);
  }

  Future<Map<String, dynamic>> updateSubscription(
    String id,
    Map<String, dynamic> data,
  ) async {
    return updateDocument(
      collectionId: subscriptionsCollection,
      documentId: id,
      data: data,
    );
  }

  Future<void> deleteSubscription(String id) async {
    await deleteDocument(collectionId: subscriptionsCollection, documentId: id);
  }
}
