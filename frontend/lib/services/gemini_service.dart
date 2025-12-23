import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/savings_goal.dart';

class GeminiService {
  static const String _apiKeyPref = 'gemini_api_key';
  static const String _aiEnabledPref = 'ai_features_enabled';

  GenerativeModel? _model;
  String? _apiKey;

  // Initialize the service with stored API key
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _apiKey = prefs.getString(_apiKeyPref);

    if (_apiKey != null && _apiKey!.isNotEmpty) {
      _model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: _apiKey!);
    }
  }

  // Save API key
  Future<bool> saveApiKey(String apiKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_apiKeyPref, apiKey);
      _apiKey = apiKey;

      // Initialize model with new key
      _model = GenerativeModel(model: 'gemini-2.5-pro', apiKey: apiKey);

      // Test the API key
      final isValid = await validateApiKey();
      return isValid;
    } catch (e) {
      return false;
    }
  }

  // Get stored API key
  Future<String?> getApiKey() async {
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
  }

  // Get comprehensive AI status
  Future<Map<String, dynamic>> getAIStatus() async {
    final isEnabled = await isAIEnabled();
    final apiKey = await getApiKey();
    final hasValidKey = apiKey != null && apiKey.isNotEmpty;
    final modelName = _model != null
        ? 'gemini-3-pro-preview'
        : 'Not initialized';

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
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Monthly Income:    ₹${monthlyIncome.toStringAsFixed(0)}
Total Expenses:    ₹${totalExpenses.toStringAsFixed(0)}
Net Savings:       ₹${(monthlyIncome - totalExpenses).toStringAsFixed(0)}
Savings Rate:      ${((monthlyIncome - totalExpenses) / monthlyIncome * 100).toStringAsFixed(1)}%

📈 CATEGORY BREAKDOWN:
${categoriesMap.entries.map((e) => '${e.key.padRight(15)} ₹${e.value.toStringAsFixed(0)}').join('\n')}

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

Keep it concise, encouraging, and actionable.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate tips at this time.';
    } catch (e) {
      throw Exception('Failed to generate tips: ${e.toString()}');
    }
  }

  // Calculate financial health score
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
    if (savingsRate >= 30) {
      score += 40;
    } else if (savingsRate >= 20) {
      score += 30;
    } else if (savingsRate >= 10) {
      score += 20;
    } else if (savingsRate > 0) {
      score += 10;
    }

    // Budget adherence (30 points)
    score += (budgetAdherence / 100) * 30;

    // Emergency fund (30 points)
    if (emergencyFundMonths >= 6) {
      score += 30;
    } else if (emergencyFundMonths >= 3) {
      score += 20;
    } else if (emergencyFundMonths >= 1) {
      score += 10;
    }

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
      // Simple date key YYYY-MM-DD
      final dateKey = expense.date.toIso8601String().split('T')[0];
      dailyTotals[dateKey] = (dailyTotals[dateKey] ?? 0) + expense.amount;
    }

    final sortedDates = dailyTotals.keys.toList()..sort();
    final trendData = sortedDates
        .map((date) => '$date: ₹${dailyTotals[date]}')
        .join('\n');

    final prompt =
        '''
📊 SPENDING TREND ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Daily Spending Data (Last $days days):
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
1. [First key insight about the pattern]
2. [Second key insight]

✅ ACTION ITEM:
[One specific, actionable recommendation based on the analysis]

Keep the response concise and data-driven.
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
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

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
Based on the following monthly expense data, predict next month's expenses:

$dataStr

Provide:
1. Predicted amount (₹)
2. Confidence level (High/Medium/Low)
3. Brief reasoning (1 sentence)

Format as JSON: {"amount": 12345, "confidence": "High", "reasoning": "..."}
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text ?? '{}';
      // Basic JSON parsing (in a real app, use a proper JSON parser with error handling)
      // This is a simplified example
      final cleanText = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      // For now, return a placeholder if parsing fails, or implement robust parsing
      return {
        'prediction': cleanText, // Return raw text for now to be safe
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get category insights
  Future<String> getCategoryInsights({
    required String category,
    required List<Expense> categoryExpenses,
  }) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    final total = categoryExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final count = categoryExpenses.length;
    final avg = count > 0 ? total / count : 0;

    final prompt =
        '''
Analyze spending in category "$category":
Total: ₹$total
Transaction Count: $count
Average per transaction: ₹${avg.toStringAsFixed(2)}

Recent transactions:
${categoryExpenses.take(5).map((e) => '- ₹${e.amount} on ${e.date.toString().split(' ')[0]}').join('\n')}

Provide 2 specific insights or tips for this category.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'No insights available.';
    } catch (e) {
      return 'Could not generate insights.';
    }
  }

  // Analyze budget performance and suggest optimizations
  Future<String> analyzeBudgetPerformance({
    required List<Budget> budgets,
    required double totalIncome,
  }) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    final budgetSummary = budgets
        .map((b) {
          return '${b.category}: ₹${b.allocatedAmount} allocated, ₹${b.spentAmount} spent (${b.percentageUsed.toStringAsFixed(1)}%)';
        })
        .join('\n');

    final prompt =
        '''
📊 BUDGET PERFORMANCE ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Monthly Income: ₹${totalIncome.toStringAsFixed(0)}

Budget Status by Category:
$budgetSummary

Please provide:

✨ PERFORMANCE SUMMARY:
[2-3 sentence overview of budget adherence]

📈 TOP PERFORMERS:
• [Category doing well and why]
• [Another strong category]

⚠️ AREAS FOR IMPROVEMENT:
• [Category needing attention]
• [Specific recommendation]

💡 OPTIMIZATION TIPS:
1. [First actionable tip to improve budget management]
2. [Second tip for better allocation]
3. [Third tip for future planning]

🎯 RECOMMENDED ACTION:
[One specific step to take this month]

Keep analysis concise and actionable.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze budget performance.';
    } catch (e) {
      throw Exception('Failed to analyze budget: ${e.toString()}');
    }
  }

  // Generate savings goal insights and motivation
  Future<String> analyzeSavingsGoals({
    required List<SavingsGoal> goals,
    required double monthlyIncome,
    required double monthlyExpenses,
  }) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    final goalsSummary = goals
        .map((g) {
          return '${g.title}: ₹${g.currentAmount}/₹${g.targetAmount} (${g.percentageCompleted.toStringAsFixed(1)}%) - ${g.daysRemaining} days left';
        })
        .join('\n');

    final monthlySavings = monthlyIncome - monthlyExpenses;

    final prompt =
        '''
💰 SAVINGS GOALS ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Monthly Income: ₹${monthlyIncome.toStringAsFixed(0)}
Monthly Expenses: ₹${monthlyExpenses.toStringAsFixed(0)}
Available for Savings: ₹${monthlySavings.toStringAsFixed(0)}

Active Goals:
$goalsSummary

Please provide:

🎯 PROGRESS OVERVIEW:
[Brief assessment of overall savings progress]

🌟 HIGHLIGHTS:
• [Goal making great progress]
• [Positive achievement or milestone]

⏰ URGENT ATTENTION NEEDED:
• [Goal requiring immediate action, if any]

💡 SMART STRATEGIES:
1. [Strategy to accelerate savings]
2. [Tip for better allocation across goals]
3. [Motivation or milestone idea]

📊 MONTHLY ALLOCATION SUGGESTION:
[Recommend how to split ₹${monthlySavings.toStringAsFixed(0)} across goals]

🚀 MOTIVATIONAL MESSAGE:
[Brief encouraging message about their savings journey]

Be motivating and practical.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to analyze savings goals.';
    } catch (e) {
      throw Exception('Failed to analyze savings: ${e.toString()}');
    }
  }

  // Generate comprehensive report insights
  Future<String> generateReportInsights({
    required double totalIncome,
    required double totalExpenses,
    required Map<String, double> categoryExpenses,
    required double lastMonthIncome,
    required double lastMonthExpenses,
  }) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    final categoryBreakdown = categoryExpenses.entries
        .map(
          (e) =>
              '${e.key}: ₹${e.value.toStringAsFixed(0)} (${(e.value / totalExpenses * 100).toStringAsFixed(1)}%)',
        )
        .join('\n');

    final incomeChange = totalIncome - lastMonthIncome;
    final expenseChange = totalExpenses - lastMonthExpenses;

    final prompt =
        '''
📈 FINANCIAL REPORT ANALYSIS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CURRENT MONTH:
━━━━━━━━━━━━━━━━━
Income: ₹${totalIncome.toStringAsFixed(0)}
Expenses: ₹${totalExpenses.toStringAsFixed(0)}
Net Balance: ₹${(totalIncome - totalExpenses).toStringAsFixed(0)}

LAST MONTH:
━━━━━━━━━━━━━━━━━
Income: ₹${lastMonthIncome.toStringAsFixed(0)}
Expenses: ₹${lastMonthExpenses.toStringAsFixed(0)}

CHANGES:
━━━━━━━━━━━━━━━━━
Income Change: ₹${incomeChange.toStringAsFixed(0)} (${lastMonthIncome > 0 ? ((incomeChange / lastMonthIncome) * 100).toStringAsFixed(1) : 0}%)
Expense Change: ₹${expenseChange.toStringAsFixed(0)} (${lastMonthExpenses > 0 ? ((expenseChange / lastMonthExpenses) * 100).toStringAsFixed(1) : 0}%)

EXPENSE BREAKDOWN:
$categoryBreakdown

Please provide:

✨ EXECUTIVE SUMMARY:
[2-3 sentence overview of financial health this month]

📊 KEY METRICS:
• Savings Rate: [Calculate percentage]
• Top Spending Category: [Identify highest]
• Month-over-Month Trend: [Improving/Declining/Stable]

🔍 DETAILED INSIGHTS:
1. [Key observation about income]
2. [Key observation about expenses]
3. [Notable trend or pattern]

💡 RECOMMENDATIONS:
1. [Actionable financial tip]
2. [Area to focus on next month]
3. [Long-term improvement suggestion]

⚠️ WARNINGS (if any):
[Any concerning trends or immediate attention needed]

🎯 FOCUS FOR NEXT MONTH:
[One specific goal to improve financial position]

Be analytical, professional, and solution-oriented.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to generate report insights.';
    } catch (e) {
      throw Exception('Failed to generate report: ${e.toString()}');
    }
  }

  // Suggest reminders based on spending history
  Future<String> suggestReminders({required List<Expense> expenses}) async {
    if (_model == null) {
      throw Exception('Gemini API not initialized.');
    }

    // Group expenses by description to find recurring ones
    final expenseDescriptions = expenses
        .map(
          (e) =>
              '${e.description.isNotEmpty ? e.description : e.category}: ₹${e.amount} on ${e.date.toString().split(' ')[0]}',
        )
        .join('\n');

    final prompt =
        '''
Based on the following expense history, suggest potential recurring reminders (bills, subscriptions, EMIs, etc.).
Look for patterns in descriptions and amounts.

Expense History:
$expenseDescriptions

Please provide suggestions in this format:
1. [Title] - [Type] - [Approx Amount] - [Frequency]
   Reason: [Why you think this is a recurring expense]

Example:
1. Netflix - Subscription - ₹199 - Monthly
   Reason: Seen multiple times with same amount.

Provide at least 3 suggestions if possible. If no clear patterns, suggest common household reminders.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Unable to suggest reminders.';
    } catch (e) {
      throw Exception('Failed to suggest reminders: ${e.toString()}');
    }
  }
}
