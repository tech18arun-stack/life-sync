import 'package:flutter/foundation.dart';
import '../models/shopping_item.dart';

class ShoppingListProvider with ChangeNotifier {
  final List<ShoppingItem> _items = [];
  bool _isLoading = false;

  List<ShoppingItem> get items => _items;
  List<ShoppingItem> get activeItems =>
      _items.where((i) => !i.isPurchased).toList();
  List<ShoppingItem> get purchasedItems =>
      _items.where((i) => i.isPurchased).toList();
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    // Note: Shopping items are stored locally for now
    // Can be extended to use MongoDB API if needed
    _isLoading = false;
    notifyListeners();
  }

  // Backward compatibility alias
  Future<void> initializeHive() async => initialize();

  void addItem(ShoppingItem item) {
    _items.add(item);
    notifyListeners();
  }

  void updateItem(ShoppingItem item) {
    final index = _items.indexWhere((i) => i.id == item.id);
    if (index != -1) {
      _items[index] = item;
      notifyListeners();
    }
  }

  void deleteItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  void togglePurchased(String id) {
    final item = _items.firstWhere((i) => i.id == id);
    item.isPurchased = !item.isPurchased;
    if (item.isPurchased) {
      item.purchasedDate = DateTime.now();
    } else {
      item.purchasedDate = null;
    }
    updateItem(item);
  }

  double getTotalEstimatedCost() {
    return activeItems.fold(
      0,
      (sum, item) => sum + (item.estimatedPrice ?? 0) * item.quantity,
    );
  }

  double getTotalActualCost() {
    return purchasedItems.fold(
      0,
      (sum, item) => sum + (item.actualPrice ?? 0) * item.quantity,
    );
  }

  Map<String, int> getItemsByCategory() {
    Map<String, int> categoryCount = {};
    for (var item in activeItems) {
      categoryCount[item.category] = (categoryCount[item.category] ?? 0) + 1;
    }
    return categoryCount;
  }

  void clearPurchased() {
    final purchasedIds = purchasedItems.map((i) => i.id).toList();
    for (var id in purchasedIds) {
      if (id != null) {
        deleteItem(id);
      }
    }
  }
}
