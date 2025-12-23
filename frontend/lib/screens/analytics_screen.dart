import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/analytics_provider.dart';
import '../widgets/spending_trends_chart.dart';
import '../widgets/category_breakdown_widget.dart';
import '../widgets/monthly_comparison_widget.dart';
import '../widgets/expense_prediction_card.dart';
import '../services/gemini_service.dart';
import '../providers/financial_data_manager.dart';
import '../widgets/ai_tips_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _geminiService = GeminiService();
  bool _aiEnabled = false;
  String? _aiAnalysis;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    await _geminiService.initialize();
    final enabled = await _geminiService.isAIEnabled();
    setState(() {
      _aiEnabled = enabled;
    });
    if (enabled) {
      _loadAIAnalysis();
    }
  }

  Future<void> _loadAIAnalysis() async {
    setState(() => _isLoadingAI = true);
    try {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );
      final expenses = financialManager.getRecentExpenses(
        limit: 60,
      ); // Get last 60 days

      if (expenses.isEmpty) {
        setState(() => _isLoadingAI = false);
        return;
      }

      final analysis = await _geminiService.analyzeTrends(
        expenses: expenses,
        days: 30,
      );

      setState(() {
        _aiAnalysis = analysis;
        _isLoadingAI = false;
      });
    } catch (e) {
      setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          if (_aiEnabled)
            IconButton(
              icon: _isLoadingAI
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _loadAIAnalysis,
            ),
        ],
      ),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, child) {
          final trends = analytics.getTrendData(days: 30);
          final categories = analytics.categoryTotals;
          final comparison = analytics.compareMonthToPrevious();
          final predictions = analytics.predictions;

          if (trends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No data available yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add some expenses to see insights',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).disabledColor,
                    ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Income Availability Overview
                Consumer<FinancialDataManager>(
                  builder: (context, financial, _) {
                    final availableBalance = financial.getAvailableBalance();
                    final monthlyAvailable = financial
                        .getMonthlyAvailableBalance();
                    final totalIncome = financial.getTotalIncome();
                    final totalExpenses = financial.getTotalExpenses();

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Financial Summary',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSummaryItem(
                                'Total Income',
                                totalIncome,
                                Icons.trending_up,
                              ),
                              _buildSummaryItem(
                                'Total Expenses',
                                totalExpenses,
                                Icons.trending_down,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Divider(color: Colors.white.withValues(alpha: 0.3)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Available Balance',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${availableBalance.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Overall',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'This Month',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₹${monthlyAvailable.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),

                // AI Analysis
                if (_aiEnabled && (_aiAnalysis != null || _isLoadingAI))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: AITipsCard(
                      tip: _aiAnalysis,
                      isLoading: _isLoadingAI,
                      onRefresh: _loadAIAnalysis,
                      title: '🤖 AI Trend Analysis',
                    ),
                  ),

                // Prediction Card
                ExpensePredictionCard(predictionData: predictions),
                const SizedBox(height: 24),

                // Spending Trends
                SpendingTrendsChart(dailySpending: trends),
                const SizedBox(height: 24),

                // Monthly Comparison
                MonthlyComparisonWidget(comparisonData: comparison),
                const SizedBox(height: 24),

                // Category Breakdown
                CategoryBreakdownWidget(categoryTotals: categories),
                const SizedBox(height: 100),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
