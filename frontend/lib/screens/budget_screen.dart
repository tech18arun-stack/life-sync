import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
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
  final _geminiService = GeminiService();
  bool _aiEnabled = false;
  bool _isLoadingAI = false;
  String? _aiAnalysis;

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
        final analysis = await _geminiService.analyzeBudgetPerformance(
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
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Budgets'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high),
            tooltip: 'Smart Plan',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SmartBudgetDialog(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_budget_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddBudgetDialog(),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
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
                    color: AppTheme.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No active budgets',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const AddBudgetDialog(),
                      );
                    },
                    child: const Text('Create your first budget'),
                  ),
                ],
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // AI Analysis Card
              if (_aiEnabled && (_aiAnalysis != null || _isLoadingAI))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
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
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Budget Status',
                              style: TextStyle(
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Available: ₹${financialManager.getMonthlyAvailableBalance().toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Spent',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${totalSpent.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
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
                                const Text(
                                  'Budgeted',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  '₹${totalBudget.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: totalBudget > 0
                                ? totalSpent / totalBudget
                                : 0,
                            backgroundColor: Colors.black26,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              totalSpent > totalBudget
                                  ? AppTheme.errorColor
                                  : AppTheme.successColor,
                            ),
                            minHeight: 8,
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
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
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

    return Dismissible(
      key: Key(budget.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Budget?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        financialManager.deleteBudget(budget.id ?? '');
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddBudgetDialog(budget: budget),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: FaIcon(
                            _getCategoryIcon(budget.category),
                            color: color,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              budget.category,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${budget.period} • Ends ${DateFormat('MMM d').format(budget.endDate)}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.color,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${budget.spentAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOverBudget
                                ? AppTheme.errorColor
                                : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        Text(
                          'of ₹${budget.allocatedAmount.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress > 1 ? 1 : progress,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? AppTheme.errorColor : color,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${budget.percentageUsed.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isOverBudget
                            ? AppTheme.errorColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isOverBudget
                          ? 'Over by ₹${(budget.spentAmount - budget.allocatedAmount).toStringAsFixed(0)}'
                          : '₹${budget.remainingAmount.toStringAsFixed(0)} left',
                      style: TextStyle(
                        color: isOverBudget
                            ? AppTheme.errorColor
                            : Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 12,
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return FontAwesomeIcons.utensils;
      case 'transport':
        return FontAwesomeIcons.bus;
      case 'health':
        return FontAwesomeIcons.heartPulse;
      case 'education':
        return FontAwesomeIcons.graduationCap;
      case 'entertainment':
        return FontAwesomeIcons.gamepad;
      case 'utilities':
        return FontAwesomeIcons.bolt;
      case 'shopping':
        return FontAwesomeIcons.bagShopping;
      default:
        return FontAwesomeIcons.circleDollarToSlot;
    }
  }
}
