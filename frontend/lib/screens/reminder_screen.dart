import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/reminder_provider.dart';
import '../providers/financial_data_manager.dart';
import '../services/gemini_service.dart';
import '../models/reminder.dart';
import '../models/expense.dart';
import '../utils/app_theme.dart';
import '../widgets/add_reminder_dialog.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Reminders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.wandMagicSparkles),
            tooltip: 'AI Suggestions',
            onPressed: () => _showAISuggestions(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add_reminder_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddReminderDialog(),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add),
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildActiveReminders(context, provider),
              _buildCompletedReminders(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveReminders(
    BuildContext context,
    ReminderProvider provider,
  ) {
    final pendingReminders = provider.getPendingReminders();
    final upcomingReminders = provider.getUpcomingReminders();
    final overdueReminders = provider.getOverdueReminders();

    if (pendingReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.bell,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No active reminders',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        if (overdueReminders.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Overdue',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return _buildReminderCard(
                context,
                overdueReminders[index],
                provider,
                isOverdue: true,
              );
            }, childCount: overdueReminders.length),
          ),
        ],
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Text(
              'Upcoming',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyLarge?.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return _buildReminderCard(
              context,
              upcomingReminders[index],
              provider,
            );
          }, childCount: upcomingReminders.length),
        ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildCompletedReminders(
    BuildContext context,
    ReminderProvider provider,
  ) {
    final completedReminders = provider.reminders
        .where((r) => r.isPaid)
        .toList();
    // Sort by paid date descending, or due date if paid date is null
    completedReminders.sort((a, b) {
      final dateA = a.paidDate ?? a.dueDate;
      final dateB = b.paidDate ?? b.dueDate;
      return dateB.compareTo(dateA);
    });

    if (completedReminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(
              FontAwesomeIcons.checkDouble,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No completed reminders yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: completedReminders.length,
      itemBuilder: (context, index) {
        return _buildCompletedReminderCard(
          context,
          completedReminders[index],
          provider,
        );
      },
    );
  }

  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider, {
    bool isOverdue = false,
  }) {
    return Dismissible(
      key: Key(reminder.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.errorColor,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteReminder(reminder.id ?? '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Reminder deleted')));
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AddReminderDialog(reminder: reminder),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isOverdue
                        ? AppTheme.errorColor.withOpacity(0.1)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    _getIconForType(reminder.type),
                    color: isOverdue
                        ? AppTheme.errorColor
                        : AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${DateFormat('MMM d, y').format(reminder.dueDate)}',
                        style: TextStyle(
                          color: isOverdue
                              ? AppTheme.errorColor
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 12,
                          fontWeight: isOverdue
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (reminder.amount != null)
                        Text(
                          '₹${reminder.amount!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () =>
                      _showCompleteDialog(context, reminder, provider),
                  icon: const Icon(Icons.check_circle_outline),
                  color: AppTheme.successColor,
                  tooltip: 'Mark as Done',
                ),
                IconButton(
                  onPressed: () =>
                      _showSnoozeDialog(context, reminder, provider),
                  icon: const Icon(Icons.snooze),
                  color: AppTheme.textSecondary,
                  tooltip: 'Snooze',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).cardColor.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.check,
                color: AppTheme.successColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Paid: ${reminder.paidDate != null ? DateFormat('MMM d, y').format(reminder.paidDate!) : 'Unknown'}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  if (reminder.amount != null)
                    Text(
                      '₹${reminder.amount!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _reworkReminder(context, reminder, provider),
              child: const Text('Rework'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnoozeDialog(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Snooze Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Tomorrow'),
              onTap: () {
                _snooze(context, reminder, provider, const Duration(days: 1));
              },
            ),
            ListTile(
              title: const Text('Next Week'),
              onTap: () {
                _snooze(context, reminder, provider, const Duration(days: 7));
              },
            ),
            ListTile(
              title: const Text('Next Month'),
              onTap: () {
                _snooze(context, reminder, provider, const Duration(days: 30));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _snooze(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
    Duration duration,
  ) {
    final newDate = reminder.dueDate.add(duration);
    final updatedReminder = Reminder(
      id: reminder.id,
      title: reminder.title,
      type: reminder.type,
      dueDate: newDate,
      amount: reminder.amount,
      description: reminder.description,
      isRecurring: reminder.isRecurring,
      recurringType: reminder.recurringType,
      notificationEnabled: reminder.notificationEnabled,
      notificationDaysBefore: reminder.notificationDaysBefore,
      isPaid: reminder.isPaid,
      paidDate: reminder.paidDate,
      linkedExpenseId: reminder.linkedExpenseId,
    );
    provider.updateReminder(updatedReminder);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Snoozed until ${DateFormat('MMM d').format(newDate)}'),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Reminder'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How would you like to complete "${reminder.title}"?'),
            if (reminder.amount != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Amount: ₹${reminder.amount!.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _reworkReminder(context, reminder, provider);
            },
            child: const Text(
              'Rework',
              style: TextStyle(color: AppTheme.warningColor),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWithExpense(context, reminder, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
            ),
            child: const Text('Complete'),
          ),
        ],
      ),
    );
  }

  void _completeWithExpense(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    String? expenseId;

    // If reminder has an amount, create an expense
    if (reminder.amount != null && reminder.amount! > 0) {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );

      // Map reminder type to expense category
      String category = 'Others';
      switch (reminder.type.toLowerCase()) {
        case 'bill':
        case 'utilities':
          category = 'Utilities';
          break;
        case 'emi':
        case 'loan':
          category = 'EMI';
          break;
        case 'recharge':
          category = 'Recharge';
          break;
        case 'subscription':
          category = 'Entertainment';
          break;
        case 'health':
          category = 'Health';
          break;
      }

      expenseId = DateTime.now().millisecondsSinceEpoch.toString();

      // Create expense from reminder
      final expense = Expense(
        id: expenseId,
        description: reminder.title,
        amount: reminder.amount!,
        category: category,
        date: DateTime.now(),
        notes: 'Auto-created from reminder: ${reminder.description ?? ""}',
        paymentMethod: 'Cash',
      );

      financialManager.addExpense(expense);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder completed and expense of ₹${reminder.amount!.toStringAsFixed(0)} created',
          ),
          backgroundColor: AppTheme.successColor,
          action: SnackBarAction(
            label: 'View',
            textColor: Colors.white,
            onPressed: () {
              Navigator.of(context).pushNamed('/expenses');
            },
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder marked as complete'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }

    // Mark reminder as paid and link expense
    final updatedReminder = Reminder(
      id: reminder.id,
      title: reminder.title,
      type: reminder.type,
      dueDate: reminder.dueDate,
      amount: reminder.amount,
      description: reminder.description,
      isRecurring: reminder.isRecurring,
      recurringType: reminder.recurringType,
      notificationEnabled: reminder.notificationEnabled,
      notificationDaysBefore: reminder.notificationDaysBefore,
      isPaid: true,
      paidDate: DateTime.now(),
      linkedExpenseId: expenseId,
    );
    provider.updateReminder(updatedReminder);
  }

  void _reworkReminder(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rework Reminder'),
        content: const Text(
          'This will move the reminder back to active list and delete any associated expense. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRework(context, reminder, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warningColor,
            ),
            child: const Text('Rework'),
          ),
        ],
      ),
    );
  }

  void _performRework(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    // Delete linked expense if exists
    if (reminder.linkedExpenseId != null) {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );
      financialManager.deleteExpense(reminder.linkedExpenseId!);
    }

    // Mark reminder as unpaid
    final updatedReminder = Reminder(
      id: reminder.id,
      title: reminder.title,
      type: reminder.type,
      dueDate: reminder.dueDate,
      amount: reminder.amount,
      description: reminder.description,
      isRecurring: reminder.isRecurring,
      recurringType: reminder.recurringType,
      notificationEnabled: reminder.notificationEnabled,
      notificationDaysBefore: reminder.notificationDaysBefore,
      isPaid: false,
      paidDate: null,
      linkedExpenseId: null,
    );
    provider.updateReminder(updatedReminder);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reminder moved to active list. Expense deleted.'),
        backgroundColor: AppTheme.warningColor,
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'bill':
        return FontAwesomeIcons.fileInvoiceDollar;
      case 'emi':
        return FontAwesomeIcons.buildingColumns;
      case 'recharge':
        return FontAwesomeIcons.mobileScreen;
      case 'loan':
        return FontAwesomeIcons.handHoldingDollar;
      case 'subscription':
        return FontAwesomeIcons.rotate;
      default:
        return FontAwesomeIcons.bell;
    }
  }

  void _showAISuggestions(BuildContext context) async {
    final geminiService = Provider.of<GeminiService>(context, listen: false);
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
      final suggestions = await geminiService.suggestReminders(
        expenses: financialProvider.expenses,
      );

      if (context.mounted) {
        Navigator.pop(context); // Close loading
        _showSuggestionsDialog(context, suggestions);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get suggestions: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showSuggestionsDialog(BuildContext context, String suggestions) {
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
                    'AI Reminder Suggestions',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Based on your spending history, here are some suggested reminders:',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      suggestions,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => const AddReminderDialog(),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Manually'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
