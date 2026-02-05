import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../models/budget.dart';
import '../utils/app_theme.dart';
import '../widgets/add_budget_dialog.dart';
import '../widgets/smart_budget_dialog.dart';
import '../services/gemini_service.dart';
import '../widgets/ai_tips_card.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  // final _geminiService = GeminiService(); // Removed

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
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;

    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Budgets',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.auto_fix_high, color: AppTheme.primaryColor),
            tooltip: 'Smart Plan',
            onPressed: () => showDialog(
              context: context,
              builder: (context) => const SmartBudgetDialog(),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_budget_fab',
        onPressed: () => showDialog(
          context: context,
          builder: (context) => const AddBudgetDialog(),
        ),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Consumer<FinancialDataManager>(
        builder: (context, financialManager, child) {
          final budgets = financialManager.getActiveBudgets();
          final totalBudget = financialManager.getTotalBudgetedAmount();
          final totalSpent = financialManager.getTotalSpentAmount();

          if (budgets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(
                    FontAwesomeIcons.piggyBank,
                    size: 64,
                    color: textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active budgets',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      color: textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (context) => const AddBudgetDialog(),
                    ),
                    child: Text(
                      'Create your first budget',
                      style: GoogleFonts.inter(color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              if (_aiEnabled && (_aiAnalysis != null || _isLoadingAI))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryColor,
                          const Color(0xFF1976D2),
                        ],
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Budget Status',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Available: ₹${financialManager.getMonthlyAvailableBalance().toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spent',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${totalSpent.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.white24,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Budgeted',
                                  style: GoogleFonts.inter(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${totalBudget.toStringAsFixed(0)}',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: totalBudget > 0
                                ? totalSpent / totalBudget
                                : 0,
                            backgroundColor: Colors.black12,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalSpent > totalBudget
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                            minHeight: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final budget = budgets[index];
                  return _buildBudgetCard(context, budget, financialManager);
                }, childCount: budgets.length),
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBudgetCard(
    BuildContext context,
    Budget budget,
    FinancialDataManager financialManager,
  ) {
    final progress = budget.percentageUsed / 100;
    final isOverBudget = budget.isOverBudget;
    final color = AppTheme.getCategoryColor(budget.category);
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return Dismissible(
      key: Key(budget.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async => await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: cardColor,
          title: Text(
            'Delete Budget?',
            style: GoogleFonts.inter(color: textPrimary),
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.inter(color: textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
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
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          onTap: () => showDialog(
            context: context,
            builder: (context) => AddBudgetDialog(budget: budget),
          ),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: FaIcon(
                        AppTheme.getCategoryIcon(budget.category),
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                          Text(
                            'Ends ${DateFormat('MMM d').format(budget.endDate)}',
                            style: GoogleFonts.inter(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${budget.allocatedAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Goal',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: textSecondary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: progress > 1 ? 1 : progress,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          color: isOverBudget ? AppTheme.errorColor : color,
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isOverBudget ? AppTheme.errorColor : color)
                                      .withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(1)}% Used',
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      isOverBudget
                          ? 'Over by ₹${(budget.spentAmount - budget.allocatedAmount).toStringAsFixed(0)}'
                          : '₹${budget.remainingAmount.toStringAsFixed(0)} left',
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
