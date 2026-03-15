import 'package:flutter/material.dart';
import '../models/subscription.dart';
import '../services/appwrite_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final AppwriteService _appwriteService = AppwriteService();
  List<Subscription> _subscriptions = [];
  bool _isLoading = false;

  List<Subscription> get subscriptions => _subscriptions;
  bool get isLoading => _isLoading;

  double get totalMonthlyCost {
    double total = 0;
    for (var sub in _subscriptions) {
      if (sub.billingCycle.toLowerCase() == 'monthly') {
        total += sub.amount;
      } else if (sub.billingCycle.toLowerCase() == 'yearly') {
        total += sub.amount / 12;
      }
    }
    return total;
  }

  Future<void> initialize() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();

    try {
      final documents = await _appwriteService.getSubscriptions();
      _subscriptions = documents.map((doc) => Subscription.fromJson(doc)).toList();
    } catch (e) {
      debugPrint('Error loading subscriptions from Appwrite: $e');
      _subscriptions = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSubscription(Subscription sub) async {
    try {
      final data = sub.toJson();
      final doc = await _appwriteService.createSubscription(data);
      _subscriptions.add(Subscription.fromJson(doc));
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding subscription to Appwrite: $e');
      rethrow;
    }
  }

  Future<void> deleteSubscription(String id) async {
    try {
      await _appwriteService.deleteSubscription(id);
      _subscriptions.removeWhere((sub) => sub.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting subscription from Appwrite: $e');
      rethrow;
    }
  }

  void clear() {
    _subscriptions = [];
    notifyListeners();
  }
}
