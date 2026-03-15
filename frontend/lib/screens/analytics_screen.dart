import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/analytics_provider.dart';
import '../widgets/spending_trends_chart.dart';
import '../widgets/category_breakdown_widget.dart';
import '../widgets/monthly_comparison_widget.dart';
import '../widgets/expense_prediction_card.dart';
import '../services/gemini_service.dart';
import '../providers/financial_data_manager.dart';
import '../widgets/ai_tips_card.dart';
import '../widgets/rewarded_ad_dialog.dart';
import '../utils/app_theme.dart';
import '../services/startio_ads.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  // final _geminiService = GeminiService(); // Removed
  bool _aiEnabled = false;
  String? _aiAnalysis;
  bool _isLoadingAI = false;
  bool _premiumUnlocked = false;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    // Initialize is handled in main, but checking here doesn't hurt
    if (!geminiService.isInitialized) {
      await geminiService.initialize();
    }
    final enabled = await geminiService.isAIEnabled();
    if (mounted) {
      setState(() {
        _aiEnabled = enabled;
      });
    }
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
      final expenses = financialManager.getRecentExpenses(limit: 60);

      if (expenses.isEmpty) {
        setState(() => _isLoadingAI = false);
        return;
      }

      final geminiService = Provider.of<GeminiService>(context, listen: false);
      final analysis = await geminiService.analyzeTrends(
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const StartioBanner(),
      body: Consumer<AnalyticsProvider>(
        builder: (context, analytics, child) {
          final trends = analytics.getTrendData(days: 30);
          final categories = analytics.categoryTotals;
          final comparison = analytics.compareMonthToPrevious();
          final predictions = analytics.predictions;

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(context),
              if (trends.isEmpty)
                SliverFillRemaining(child: _buildEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildFinancialSummaryCard(context),
                      const SizedBox(height: 24),

                      // AI Analysis
                      if (_aiEnabled &&
                          (_aiAnalysis != null ||
                              _isLoadingAI ||
                              _premiumUnlocked))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: AITipsCard(
                            tip: _premiumUnlocked
                                ? _aiAnalysis
                                : 'Watch ad to unlock premium insights',
                            isLoading: _isLoadingAI,
                            onRefresh: _loadAIAnalysis,
                            title: '🤖 AI Trend Analysis',
                          ),
                        ),

                      // Watch Ad for Premium Features
                      if (_aiEnabled && !_premiumUnlocked)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: _buildPremiumUnlockCard(context),
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
                      const Center(child: StartioMrec()),
                      const SizedBox(height: 24),

                      // Category Breakdown
                      CategoryBreakdownWidget(categoryTotals: categories),
                      const SizedBox(height: 80),
                    ]),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back_ios_new, size: 16),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        if (_aiEnabled)
          IconButton(
            icon: _isLoadingAI
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.arrowsRotate,
                      size: 16,
                    ),
                  ),
            onPressed: _loadAIAnalysis,
          ),
        const SizedBox(width: 16),
      ],
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
        title: Text(
          'Analytics',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.bodyLarge?.color,
            fontSize: 20,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryColor.withValues(alpha: 0.05),
                Theme.of(context).scaffoldBackgroundColor,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialSummaryCard(BuildContext context) {
    return Consumer<FinancialDataManager>(
      builder: (context, financial, _) {
        final availableBalance = financial.getAvailableBalance();
        final monthlyAvailable = financial.getMonthlyAvailableBalance();
        final totalIncome = financial.getTotalIncome();
        final totalExpenses = financial.getTotalExpenses();

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryColor, const Color(0xFF6C63FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Overview',
                    style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryColumn(
                      'Income',
                      totalIncome,
                      Icons.arrow_upward,
                      const Color(0xFF4ADE80), // Light green
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20),
                      child: _buildSummaryColumn(
                        'Expenses',
                        totalExpenses,
                        Icons.arrow_downward,
                        const Color(0xFFF87171), // Light red
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Balance',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${availableBalance.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'This Month',
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${monthlyAvailable.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryColumn(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          '₹${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumUnlockCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF6C63FF), const Color(0xFF8B85FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock Premium Insights',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watch a short video to unlock AI analysis',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => RewardedAdDialog(
                    featureName: 'AI Analytics',
                    onRewardEarned: () {
                      setState(() {
                        _premiumUnlocked = true;
                      });
                      // Load AI analysis after unlocking
                      _loadAIAnalysis();
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF6C63FF),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.play_circle_filled, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Watch & Unlock',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              FontAwesomeIcons.chartPie,
              size: 50,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track expenses to see analytics',
            style: GoogleFonts.inter(color: Theme.of(context).disabledColor),
          ),
        ],
      ),
    );
  }
}
