import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

class GeminiService extends ChangeNotifier {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String _aiEnabledPref = 'ai_features_enabled';

  // Use a stable, capable model
  static const String _modelName = 'gemini-1.5-flash';

  GenerativeModel? _model;
  String? _apiKey;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  String? get currentApiKey => _apiKey;

  // Initialize the service with stored API key
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: _modelName, apiKey: _apiKey!);
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Save API key
  Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, apiKey);
      _apiKey = apiKey;

      // Initialize model with new key
      _model = GenerativeModel(model: _modelName, apiKey: apiKey);

      // Test the API key
      final isValid = await validateApiKey();

      _isInitialized = isValid;
      notifyListeners();

      return isValid;
    } catch (e) {
      _isInitialized = false;
      notifyListeners();
      return false;
    }
  }

  // Get stored API key
  Future<String?> getApiKey() async {
    if (_apiKey != null) return _apiKey;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiKeyPref);
  }

  // Validate API key
  Future<bool> validateApiKey() async {
    if (_model == null) return false;

    try {
      final response = await _model!.generateContent([Content.text('Hello')]);
      return response.text != null;
    } catch (e) {
      debugPrint('Gemini Validation Error: $e');
      return false;
    }
  }

  // Check if AI features are enabled
  Future<bool> isAIEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_aiEnabledPref) ?? false;
  }

  // Toggle AI features
  Future<void> setAIEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_aiEnabledPref, enabled);
    notifyListeners();
  }

  // Get comprehensive AI status
  Future<Map<String, dynamic>> getAIStatus() async {
    final isEnabled = await isAIEnabled();
    final apiKey = await getApiKey();
    final hasValidKey = apiKey != null && apiKey.isNotEmpty;
    final modelName = _model != null ? _modelName : 'Not initialized';

    return {
      'enabled': isEnabled,
      'hasApiKey': hasValidKey,
      'modelName': modelName,
      'ready': isEnabled && hasValidKey && _model != null,
    };
  }

  // Generate budget tips based on spending patterns
  Future<String> generateBudgetTips({
    required List<Expense> expenses,
    required List<Budget> budgets,
    required double monthlyIncome,
  }) async {
    if (_model == null) {
      throw Exception(
        'Gemini API not initialized. Please set your API key in settings.',
      );
    }

    final totalExpenses = expenses.fold<double>(
      0,
      (sum, expense) => sum + expense.amount,
    );

    final categoriesMap = <String, double>{};
    for (final expense in expenses) {
      categoriesMap[expense.category] =
          (categoriesMap[expense.category] ?? 0) + expense.amount;
    }

    final budgetInfo = budgets
        .map((b) {
          return '${b.category}: ₹${b.allocatedAmount} allocated, ₹${b.spentAmount} spent';
        })
        .join(', ');

    final prompt =
        '''
You are a financial advisor helping a family manage their budget.

📊 FINANCIAL SUMMARY:
Monthly Income:    ₹${monthlyIncome.toStringAsFixed(0)}
Total Expenses:    ₹${totalExpenses.toStringAsFixed(0)}
Net Savings:       ₹${(monthlyIncome - totalExpenses).toStringAsFixed(0)}
Savings Rate:      ${monthlyIncome > 0 ? ((monthlyIncome - totalExpenses) / monthlyIncome * 100).toStringAsFixed(1) : 0}%

📈 CATEGORY BREAKDOWN:
${categoriesMap.entries.map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}').join('\n')}

💰 BUDGET STATUS:
$budgetInfo

Please provide your analysis in this format:

✨ KEY INSIGHTS:
[Brief 2-3 sentence overview of the financial situation]

💡 RECOMMENDATIONS:
1. [First practical tip]
2. [Second practical tip]
3. [Third practical tip]

⚠️ PRIORITY ACTION:
[Most important thing to focus on this month]

Keep it concise, encouraging, and actionable. Do not use markdown bolding too heavily.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate tips at this time.';
    } catch (e) {
      throw Exception('Failed to generate tips: ${e.toString()}');
    }
  }

  // Calculate financial health score locally (deterministic)
  Map<String, dynamic> calculateFinancialHealth({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double totalSavings,
    required List<Budget> budgets,
  }) {
    final savingsRate = monthlyIncome > 0
        ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100)
        : 0.0;

    final budgetsOnTrack = budgets.where((b) => !b.isOverBudget).length;
    final budgetAdherence = budgets.isEmpty
        ? 0.0
        : (budgetsOnTrack / budgets.length * 100);

    final emergencyFundMonths = monthlyExpenses > 0
        ? totalSavings / monthlyExpenses
        : 0.0;

    double score = 0;

    // Savings rate (40 points)
    if (savingsRate >= 30)
      score += 40;
    else if (savingsRate >= 20)
      score += 30;
    else if (savingsRate >= 10)
      score += 20;
    else if (savingsRate > 0)
      score += 10;

    // Budget adherence (30 points)
    score += (budgetAdherence / 100) * 30;

    // Emergency fund (30 points)
    if (emergencyFundMonths >= 6)
      score += 30;
    else if (emergencyFundMonths >= 3)
      score += 20;
    else if (emergencyFundMonths >= 1)
      score += 10;

    score = score.clamp(0, 100);

    String rating;
    String message;

    if (score >= 80) {
      rating = 'Excellent';
      message = 'Your financial health is outstanding! Keep up the great work.';
    } else if (score >= 60) {
      rating = 'Good';
      message =
          'You\'re doing well! A few improvements could make it even better.';
    } else if (score >= 40) {
      rating = 'Fair';
      message =
          'There\'s room for improvement. Focus on building savings and sticking to budgets.';
    } else {
      rating = 'Needs Attention';
      message =
          'Your finances need some work. Consider creating a budget and reducing expenses.';
    }

    return {
      'score': score.round(),
      'rating': rating,
      'message': message,
      'savingsRate': savingsRate,
      'budgetAdherence': budgetAdherence,
      'emergencyFundMonths': emergencyFundMonths,
    };
  }

  // Analyze spending trends
  Future<String> analyzeTrends({
    required List<Expense> expenses,
    required int days,
  }) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    final dailyTotals = <String, double>{};
    for (final expense in expenses) {
      final dateKey = expense.date.toIso8601String().split('T')[0];
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    final sortedDates = dailyTotals.keys.toList()..sort();
    final trendData = sortedDates
        .map((date) => '$date: ₹${dailyTotals[date]}')
        .join('\n');

    final prompt =
        '''
📊 SPENDING TREND ANALYSIS (Last $days days):
$trendData

Please analyze this data and provide:

📈 TREND OVERVIEW:
[Brief 1-2 sentence summary of the overall trend]

🔍 KEY OBSERVATIONS:
• Spending Pattern: [Increasing/Decreasing/Stable]
• Average Daily Spend: [Calculate from data]
• Highest Spending Day: [Date and amount]
• Notable Spikes: [Any unusual spending days]

💡 INSIGHTS:
1. [First key insight]
2. [Second key insight]

✅ ACTION ITEM:
[One specific, actionable recommendation]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze trends.';
    } catch (e) {
      throw Exception('Failed to analyze trends: ${e.toString()}');
    }
  }

  // Predict monthly expenses
  Future<Map<String, dynamic>> predictMonthlyExpenses({
    required List<Expense> historicalExpenses,
    required int monthsBack,
  }) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    // Pre-aggregate data
    final monthlyData = <String, double>{};
    for (final expense in historicalExpenses) {
      final monthKey =
          '${expense.date.year}-${expense.date.month.toString().padLeft(2, '0')}';
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + expense.amount;
    }

    final dataStr = monthlyData.entries
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(2)}')
        .join('\n');

    final prompt =
        '''
Based on this monthly expense data:
$dataStr

Predict next month's expenses. Return STRICT JSON only:
{
  "prediction": "12345",
  "confidence": "High/Medium/Low",
  "reasoning": "Brief one sentence reasoning"
}
''';

    try {
      // Force JSON mode if possible with generation config, but text prompting works for older versions
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';

      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      try {
        final Map<String, dynamic> json = jsonDecode(cleanText);
        // Ensure prediction is a string or number converted to string for consistency
        if (json['prediction'] is int || json['prediction'] is double) {
          json['prediction'] = json['prediction'].toString();
        }
        return json;
      } catch (e) {
        // Fallback manual parse if JSON decode fails
        return {
          'prediction': 'N/A',
          'confidence': 'Low',
          'reasoning': 'Could not parse prediction.',
        };
      }
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Category insights
  Future<String> getCategoryInsights({
    required String category,
    required List<Expense> categoryExpenses,
  }) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    final total = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final count = categoryExpenses.length;
    final avg = count > 0 ? total / count : 0;

    final recent = categoryExpenses
        .take(5)
        .map((e) => '- ₹${e.amount} on ${e.date.toString().split(' ')[0]}')
        .join('\n');

    final prompt =
        '''
Analyze spending in category "$category":
Total: ₹$total
Count: $count
Avg: ₹${avg.toStringAsFixed(2)}

Recent:
$recent

Provide 2 short, specific 💡 tips for this category.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'No message.';
    } catch (e) {
      return 'Could not generate insights.';
    }
  }

  // Budget Performance
  Future<String> analyzeBudgetPerformance({
    required List<Budget> budgets,
    required double totalIncome,
  }) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    final budgetSummary = budgets
        .map((b) {
          return '${b.category}: ₹${b.allocatedAmount} allocated, ₹${b.spentAmount} spent (${b.percentageUsed.toStringAsFixed(1)}%)';
        })
        .join('\n');

    final prompt =
        '''
Analyze this budget performance (Income: ₹${totalIncome.toStringAsFixed(0)}):
$budgetSummary

Provide:
✨ PERFORMANCE SUMMARY: [One sentence]
📈 BEST CATEGORY: [Name and why]
⚠️ NEEDS ATTENTION: [Name and why]
💡 TIP: [One key optimization tip]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Analysis unavailable.';
    } catch (e) {
      throw Exception('Failed to analyze budget: ${e.toString()}');
    }
  }

  // Savings Goals Analysis
  Future<String> analyzeSavingsGoals({
    required List<SavingsGoal> goals,
    required double monthlyIncome,
    required double monthlyExpenses,
  }) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    final goalsSummary = goals
        .map((g) {
          return '${g.title}: ₹${g.currentAmount}/₹${g.targetAmount} (${g.percentageCompleted.toStringAsFixed(1)}%)';
        })
        .join('\n');

    final savings = monthlyIncome - monthlyExpenses;

    final prompt =
        '''
Analyze savings (Available: ₹${savings.toStringAsFixed(0)}):
$goalsSummary

Provide:
🎯 STATUS: [Brief overview]
🔥 HOT STREAK: [Best goal]
🚀 MOTIVATION: [One sentence encouragement]
💡 STRATEGY: [One tip to save faster]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Analysis unavailable.';
    } catch (e) {
      throw Exception('Failed to analyze savings: ${e.toString()}');
    }
  }

  // Generate report insights
  Future<String> generateReportInsights({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    required double lastMonthIncome,
    required double lastMonthExpenses,
  }) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    final topCategories = categoryExpenses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categorySummary = topCategories
        .take(5)
        .map((e) => '${e.key}: ₹${e.value.toStringAsFixed(0)}')
        .join('\n');

    final prompt =
        '''
FINANCIAL REPORT:
Current Month: Inc ₹$totalIncome, Exp ₹$totalExpenses
Last Month: Inc ₹$lastMonthIncome, Exp ₹$lastMonthExpenses

Top Expenses:
$categorySummary

Provide:
✨ SUMMARY: [2 sentences]
📊 TENDENCY: [Better/Worse vs last month and why]
💡 ADVICE: [1 key recommendation]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Report unavailable.';
    } catch (e) {
      throw Exception('Failed to generate report: ${e.toString()}');
    }
  }

  // Suggest Reminders
  Future<String> suggestReminders({required List<Expense> expenses}) async {
    if (_model == null) throw Exception('Gemini API not initialized.');

    // Simplification for token limits
    final simplifiedExpenses = expenses
        .take(30)
        .map((e) => '${e.description}: ₹${e.amount}')
        .join('\n');

    final prompt =
        '''
Suggest recurring reminders (bills/subs) based on these expenses:
$simplifiedExpenses

Format:
1. [Name] - [Type] - [Amount]
   Reason: [Why]
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'No suggestions.';
    } catch (e) {
      throw Exception('Failed to suggest reminders: ${e.toString()}');
    }
  }
}
