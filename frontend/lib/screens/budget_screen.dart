import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../models/budget.dart';
import '../utils/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/premium_components.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/smart_budget_dialog.dart';
import '../services/gemini_service.dart';
import '../services/startio_ads.dart';
import '../widgets/ai_tips_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  bool _aiEnabled = false;
  bool _isLoadingAI = false;
  String? _aiAnalysis;

  @override
  void initState() {
    super.initState();
    _initializeAI();
  }

  Future<void> _initializeAI() async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final enabled = await geminiService.isAIEnabled();
    setState(() => _aiEnabled = enabled);
    if (_aiEnabled) {
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
      final budgets = financialManager.getActiveBudgets();
      final income = financialManager.getMonthlyIncome();

      if (budgets.isNotEmpty) {
        final geminiService = Provider.of<GeminiService>(
          context,
          listen: false,
        );
        final analysis = await geminiService.analyzeBudgetPerformance(
          budgets: budgets,
          totalIncome: income,
        );
        setState(() {
          _aiAnalysis = analysis;
          _isLoadingAI = false;
        });
      } else {
        setState(() => _isLoadingAI = false);
      }
    } catch (e) {
      setState(() => _isLoadingAI = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      bottomNavigationBar: const StartioBanner(),
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: GoogleFonts.inter(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textPrimary,
            letterSpacing: -1,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.auto_fix_high,
                color: AppTheme.primaryColor,
                size: 20,
              ),
            ),
            tooltip: 'Smart Plan',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const SmartBudgetDialog(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: PremiumFAB(
        icon: Icons.add,
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddBudgetDialog(),
          );
          await StartIOAds.showInterstitial(context);
        },
      ),
      body: Consumer<FinancialDataManager>(
        builder: (context, financialManager, child) {
          final budgets = financialManager.getActiveBudgets();
          final totalBudget = financialManager.getTotalBudgetedAmount();
          final totalSpent = financialManager.getTotalSpentAmount();

          if (budgets.isEmpty) {
            return _buildEmptyState(context, textPrimary, textSecondary);
          }

          return _buildBudgetList(
            context,
            financialManager,
            budgets,
            totalBudget,
            totalSpent,
            textPrimary,
            textSecondary,
            isDesktop,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 40 : 32),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              shape: BoxShape.circle,
              boxShadow: [AppTheme.softShadow],
            ),
            child: FaIcon(
              FontAwesomeIcons.piggyBank,
              size: isDesktop ? 80 : 64,
              color: textSecondary.withValues(alpha: 0.3),
            ),
          ),
          SizedBox(height: isDesktop ? 24 : 16),
          Text(
            'No active budgets',
            style: GoogleFonts.inter(
              fontSize: Responsive.getFontSize(context, FontSizeType.title),
              color: textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (context) => const AddBudgetDialog(),
              );
              if (mounted) await StartIOAds.showInterstitial(context);
            },
            child: Text(
              'Create your first budget',
              style: GoogleFonts.inter(color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetList(
    BuildContext context,
    FinancialDataManager financialManager,
    List<Budget> budgets,
    double totalBudget,
    double totalSpent,
    Color textPrimary,
    Color textSecondary,
    bool isDesktop,
  ) {
    return CustomScrollView(
      slivers: [
        if (_aiEnabled && (_aiAnalysis != null || _isLoadingAI))
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 24 : 20,
                isDesktop ? 24 : 20,
                isDesktop ? 24 : 20,
                0,
              ),
              child: AITipsCard(
                tip: _aiAnalysis,
                isLoading: _isLoadingAI,
                onRefresh: _loadAIAnalysis,
                title: '🤖 AI Budget Analysis',
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            child: _buildTotalBudgetCard(
              context,
              financialManager,
              totalBudget,
              totalSpent,
            ),
          ),
        ),

        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) =>
                _buildBudgetCard(context, budgets[index], financialManager)
                    .animate(delay: (index * 50).ms)
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: 0.1, curve: Curves.easeOutQuad),
            childCount: budgets.length,
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildTotalBudgetCard(
    BuildContext context,
    FinancialDataManager financialManager,
    double totalBudget,
    double totalSpent,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final isTablet = Responsive.isTablet(context);
    final cardRadius = Responsive.getCardRadius(context);
    final progress = totalBudget > 0
        ? (totalSpent / totalBudget).toDouble()
        : 0.0;

    return Container(
      padding: EdgeInsets.all(isDesktop ? 32 : (isTablet ? 28 : 24)),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.pie_chart,
              color: Colors.white.withOpacity(0.15),
              size: 100,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Budget Status',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '₹${financialManager.getMonthlyAvailableBalance().toStringAsFixed(0)} Free',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Spent',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###', 'en_IN').format(totalSpent)}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isDesktop ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Budget',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${NumberFormat('#,##,###', 'en_IN').format(totalBudget)}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: isDesktop ? 32 : 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.black.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalSpent > totalBudget
                        ? AppTheme.errorColor
                        : Colors.white,
                  ),
                  minHeight: 12,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}% of budget used',
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (totalSpent > totalBudget)
                    Text(
                      'Over budget!',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    Budget budget,
    FinancialDataManager financialManager,
  ) {
    final isDesktop = Responsive.isDesktop(context);
    final progress = budget.percentageUsed / 100;
    final isOverBudget = budget.isOverBudget;
    final color = AppTheme.getCategoryColor(budget.category);
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final cardRadius = Responsive.getCardRadius(context);

    return Dismissible(
      key: Key(budget.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: isDesktop ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async => await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: AppTheme.errorColor),
              const SizedBox(width: 12),
              Text(
                'Delete Budget?',
                style: GoogleFonts.inter(color: textPrimary),
              ),
            ],
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.inter(color: textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: AppTheme.errorColor),
              ),
            ),
          ],
        ),
      ),
      onDismissed: (direction) =>
          financialManager.deleteBudget(budget.id ?? ''),
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isDesktop ? 24 : 20,
          vertical: isDesktop ? 10 : 8,
        ),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: (isOverBudget ? AppTheme.errorColor : color).withOpacity(
              0.1,
            ),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AddBudgetDialog(budget: budget),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isDesktop ? 14 : 12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: FaIcon(
                        AppTheme.getCategoryIcon(budget.category),
                        color: color,
                        size: isDesktop ? 20 : 18,
                      ),
                    ),
                    SizedBox(width: isDesktop ? 20 : 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.category,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Ends ${DateFormat('MMM d').format(budget.endDate)}',
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##,###', 'en_IN').format(budget.allocatedAmount)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Allocated',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: isDesktop ? 24 : 20),
                Stack(
                  children: [
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: textSecondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress > 1 ? 1 : progress,
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              isOverBudget ? AppTheme.errorColor : color,
                              (isOverBudget ? AppTheme.errorColor : color)
                                  .withOpacity(0.7),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isOverBudget ? AppTheme.errorColor : color)
                                      .withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            (isOverBudget
                                    ? AppTheme.errorColor
                                    : AppTheme.successColor)
                                .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${(progress * 100).toStringAsFixed(1)}% Used',
                        style: GoogleFonts.inter(
                          color: isOverBudget
                              ? AppTheme.errorColor
                              : AppTheme.successColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      isOverBudget
                          ? 'Over by ₹${NumberFormat('#,##,###', 'en_IN').format(budget.spentAmount - budget.allocatedAmount)}'
                          : '₹${NumberFormat('#,##,###', 'en_IN').format(budget.remainingAmount)} left',
                      style: GoogleFonts.inter(
                        color: isOverBudget
                            ? AppTheme.errorColor
                            : AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
