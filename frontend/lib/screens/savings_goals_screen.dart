import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/savings_goal.dart';
import '../providers/savings_goal_provider.dart';
import '../providers/financial_data_manager.dart';
import '../services/gemini_service.dart';
import '../utils/app_theme.dart';

class SavingsGoalsScreen extends StatelessWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        title: const Text('Savings Goals'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
            tooltip: 'AI Insights',
            onPressed: () => _showAIInsights(context),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.plus),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
      body: Consumer<SavingsGoalProvider>(
        builder: (context, provider, child) {
          final activeGoals = provider.getActiveGoals();
          final completedGoals = provider.getCompletedGoals();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Card
                _buildSummaryCard(provider),
                const SizedBox(height: 24),

                // Active Goals
                if (activeGoals.isNotEmpty) ...[
                  Text(
                    'Active Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...activeGoals.map((goal) => _buildGoalCard(context, goal)),
                  const SizedBox(height: 24),
                ],

                // Completed Goals
                if (completedGoals.isNotEmpty) ...[
                  Text(
                    'Completed Goals',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...completedGoals.map(
                    (goal) => _buildGoalCard(context, goal),
                  ),
                ],

                if (activeGoals.isEmpty && completedGoals.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.piggyBank,
                            size: 64,
                            color: AppTheme.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No savings goals yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to create your first goal',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(SavingsGoalProvider provider) {
    final totalTarget = provider.getTotalSavingsTarget();
    final totalCurrent = provider.getTotalSavingsCurrent();
    final progress = provider.getSavingsProgress();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(FontAwesomeIcons.chartLine, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              const Text(
                'Total Savings Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
                    'Current',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '₹${totalCurrent.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Target',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '₹${totalTarget.toStringAsFixed(0)}',
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
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${progress.toStringAsFixed(1)}% complete',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: goal.isCompleted
              ? Colors.green.withOpacity(0.5)
              : AppTheme.borderColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (goal.emoji.isNotEmpty)
                Text(goal.emoji, style: const TextStyle(fontSize: 32)),
              if (goal.emoji.isNotEmpty) const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            goal.title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getPriorityColor(
                              goal.priority,
                            ).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getPriorityColor(goal.priority),
                            ),
                          ),
                          child: Text(
                            goal.priority,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(goal.priority),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (goal.description != null)
                      Text(
                        goal.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const FaIcon(FontAwesomeIcons.circlePlus, size: 20),
                color: AppTheme.primaryColor,
                tooltip: 'Quick Add',
                onPressed: () => _showAddMoneyDialog(context, goal),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'add') {
                    _showAddMoneyDialog(context, goal);
                  } else if (value == 'edit') {
                    _showEditGoalDialog(context, goal);
                  } else if (value == 'delete') {
                    _deleteGoal(context, goal.id ?? '');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'add',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.plus, size: 16),
                        SizedBox(width: 12),
                        Text('Add Money'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.penToSquare, size: 16),
                        SizedBox(width: 12),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        FaIcon(FontAwesomeIcons.trash, size: 16),
                        SizedBox(width: 12),
                        Text('Delete'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹${goal.currentAmount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                '₹${goal.targetAmount.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: goal.percentageCompleted / 100,
              minHeight: 8,
              backgroundColor: AppTheme.borderColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? Colors.green : AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.percentageCompleted.toStringAsFixed(1)}% complete',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
              if (!goal.isCompleted)
                Row(
                  children: [
                    FaIcon(
                      FontAwesomeIcons.clock,
                      size: 12,
                      color: AppTheme.textTertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.daysRemaining} days left',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
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

  void _showAddGoalDialog(BuildContext context) {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'vacation';
    String selectedPriority = 'Medium';
    String? selectedEmoji = '🎯';
    DateTime targetDate = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Create Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          '🎯',
                          '💰',
                          '🏠',
                          '✈️',
                          '🎓',
                          '🚗',
                          '💍',
                          '📱',
                          '💻',
                          '🏥',
                          '👶',
                          '🎉',
                          '🐶',
                          '🐱',
                        ].map((emoji) {
                          return GestureDetector(
                            onTap: () => setState(() => selectedEmoji = emoji),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedEmoji == emoji
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedEmoji == emoji
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'vacation',
                      child: Text('Vacation'),
                    ),
                    DropdownMenuItem(
                      value: 'education',
                      child: Text('Education'),
                    ),
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Emergency Fund'),
                    ),
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
                    DropdownMenuItem(
                      value: 'retirement',
                      child: Text('Retirement'),
                    ),
                    DropdownMenuItem(value: 'gadgets', child: Text('Gadgets')),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text('Investment'),
                    ),
                    DropdownMenuItem(value: 'charity', child: Text('Charity')),
                    DropdownMenuItem(
                      value: 'business',
                      child: Text('Business'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: 'Medium',
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPriority = value);
                    }
                  },
                  onSaved: (value) {
                    // We will capture this in the button press
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Target Date'),
                  subtitle: Text(
                    '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                  ),
                  trailing: const FaIcon(FontAwesomeIcons.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() => targetDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    targetController.text.isNotEmpty) {
                  final goal = SavingsGoal(
                    id: null, // Don't generate UUID - let MongoDB create the _id
                    name: titleController.text,
                    targetAmount: double.parse(targetController.text),
                    targetDate: targetDate,
                    category: selectedCategory,
                    notes: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    priority: selectedPriority,
                  );
                  Provider.of<SavingsGoalProvider>(
                    context,
                    listen: false,
                  ).addGoal(goal);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMoneyDialog(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text('Add to ${goal.title}'),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Amount',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (amountController.text.isNotEmpty) {
                Provider.of<SavingsGoalProvider>(
                  context,
                  listen: false,
                ).addToGoal(goal.id!, double.parse(amountController.text));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, SavingsGoal goal) {
    final titleController = TextEditingController(text: goal.title);
    final targetController = TextEditingController(
      text: goal.targetAmount.toString(),
    );
    final descriptionController = TextEditingController(text: goal.description);
    String selectedCategory = goal.category;
    String? selectedEmoji = goal.emoji;
    String selectedPriority = goal.priority;
    DateTime targetDate =
        goal.targetDate ?? DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text('Edit Savings Goal'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Emoji Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children:
                        [
                          '🎯',
                          '💰',
                          '🏠',
                          '✈️',
                          '🎓',
                          '🚗',
                          '💍',
                          '📱',
                          '💻',
                          '🏥',
                          '👶',
                          '🎉',
                          '🐶',
                          '🐱',
                        ].map((emoji) {
                          return GestureDetector(
                            onTap: () => setState(() => selectedEmoji = emoji),
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: selectedEmoji == emoji
                                    ? AppTheme.primaryColor.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: selectedEmoji == emoji
                                      ? AppTheme.primaryColor
                                      : AppTheme.borderColor,
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Goal Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Target Amount',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'vacation',
                      child: Text('Vacation'),
                    ),
                    DropdownMenuItem(
                      value: 'education',
                      child: Text('Education'),
                    ),
                    DropdownMenuItem(
                      value: 'emergency',
                      child: Text('Emergency Fund'),
                    ),
                    DropdownMenuItem(value: 'home', child: Text('Home')),
                    DropdownMenuItem(value: 'car', child: Text('Car')),
                    DropdownMenuItem(value: 'wedding', child: Text('Wedding')),
                    DropdownMenuItem(
                      value: 'retirement',
                      child: Text('Retirement'),
                    ),
                    DropdownMenuItem(value: 'gadgets', child: Text('Gadgets')),
                    DropdownMenuItem(
                      value: 'investment',
                      child: Text('Investment'),
                    ),
                    DropdownMenuItem(value: 'charity', child: Text('Charity')),
                    DropdownMenuItem(
                      value: 'business',
                      child: Text('Business'),
                    ),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'High', child: Text('High')),
                    DropdownMenuItem(value: 'Medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'Low', child: Text('Low')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedPriority = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Target Date'),
                  subtitle: Text(
                    '${targetDate.day}/${targetDate.month}/${targetDate.year}',
                  ),
                  trailing: const FaIcon(FontAwesomeIcons.calendar),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: targetDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 3650)),
                    );
                    if (date != null) {
                      setState(() => targetDate = date);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    targetController.text.isNotEmpty) {
                  final updatedGoal = SavingsGoal(
                    id: goal.id,
                    name: titleController.text,
                    targetAmount: double.parse(targetController.text),
                    currentAmount: goal.currentAmount,
                    targetDate: targetDate,
                    category: selectedCategory,
                    notes: descriptionController.text.isEmpty
                        ? null
                        : descriptionController.text,
                    priority: selectedPriority,
                  );
                  Provider.of<SavingsGoalProvider>(
                    context,
                    listen: false,
                  ).updateGoal(updatedGoal);
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteGoal(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete Goal'),
        content: const Text('Are you sure you want to delete this goal?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Provider.of<SavingsGoalProvider>(
                context,
                listen: false,
              ).deleteGoal(id);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return AppTheme.errorColor;
      case 'Medium':
        return AppTheme.primaryColor;
      case 'Low':
        return AppTheme.successColor;
      default:
        return AppTheme.textSecondary;
    }
  }

  void _showAIInsights(BuildContext context) async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
    final savingsProvider = Provider.of<SavingsGoalProvider>(
      context,
      listen: false,
    );
    final financialProvider = Provider.of<FinancialDataManager>(
      context,
      listen: false,
    );

    // Check if AI is enabled
    final aiStatus = await geminiService.getAIStatus();
    if (!aiStatus['ready']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'AI features are not enabled. Please check settings.',
            ),
          ),
        );
      }
      return;
    }

    if (context.mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      final monthlyExpenses = financialProvider
          .getExpensesByDateRange(startOfMonth, endOfMonth)
          .fold(0.0, (sum, expense) => sum + expense.amount);

      final insights = await geminiService.analyzeSavingsGoals(
        goals: savingsProvider.goals,
        monthlyIncome: financialProvider.getMonthlyIncome(),
        monthlyExpenses: monthlyExpenses,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        _showInsightsDialog(context, insights);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate insights: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showInsightsDialog(BuildContext context, String insights) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'AI Savings Advisor',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(
                  insights,
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
