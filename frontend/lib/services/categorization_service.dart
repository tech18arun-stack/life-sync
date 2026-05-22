import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

class CategorizationService {
  final GeminiService _geminiService;

  CategorizationService(this._geminiService);

  // Default category mapping for offline / fallback
  final Map<String, List<String>> _offlineMappings = {
    'Food & Dining': ['Zomato', 'Swiggy', 'Restaurant', 'Cafe', 'Dining', 'Pizza', 'KFC', 'Burger', 'Blinkit', 'Zepto'],
    'Travel': ['Uber', 'Ola', 'Rapido', 'Redbus', 'Indigo', 'IRCTC', 'Metro', 'Traffic', 'Parking'],
    'Shopping': ['Amazon', 'Flipkart', 'Myntra', 'Ajio', 'Retail', 'Supermarket', 'Dmart', 'Reliancedigital'],
    'Bills & Utilities': ['Airtel', 'Jio', 'Vi', 'Electricity', 'Water', 'Gas', 'Electricity', 'BESCOM', 'Recharge'],
    'Entertainment': ['Netflix', 'Hotstar', 'Prime Video', 'Theatre', 'Movie', 'Bookmyshow', 'Spotify'],
    'Health': ['Apollo', 'Pharmeasy', 'Hospital', 'Clinic', 'Medicine', 'Medical'],
    'Investment': ['Zerodha', 'Groww', 'Upstox', 'SIP', 'Mutual Fund'],
  };

  String getOfflineCategory(String description) {
    final lowerDesc = description.toLowerCase();
    
    for (var entry in _offlineMappings.entries) {
      if (entry.value.any((keyword) => lowerDesc.contains(keyword.toLowerCase()))) {
        return entry.key;
      }
    }
    
    return 'Other';
  }

  Future<String> categorize(String description) async {
    // 1. Try Offline first (fast)
    final offlineCat = getOfflineCategory(description);
    if (offlineCat != 'Other') return offlineCat;

    // 2. Try Gemini if online and enabled
    try {
      final aiStatus = await _geminiService.getAIStatus();
      if (aiStatus['ready'] == true) {
        return await _geminiService.categorizeTransaction(description);
      }
    } catch (e) {
      debugPrint('Gemini categorization failed: $e');
    }

    return 'Other';
  }
}
