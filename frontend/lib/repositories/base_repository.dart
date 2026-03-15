/// Base Repository providing common CRUD operations
///
/// This repository pattern provides a clean separation between
/// the data layer (Appwrite) and the business logic (Providers).
abstract class BaseRepository<T> {
  /// Create a new item
  Future<T> create(T item);

  /// Get all items for current user
  Future<List<T>> getAll({Map<String, dynamic>? filters});

  /// Get a single item by ID
  Future<T?> getById(String id);

  /// Update an existing item
  Future<T> update(String id, T item);

  /// Delete an item
  Future<void> delete(String id);

  /// Delete multiple items
  Future<void> deleteAll(List<String> ids);
}
