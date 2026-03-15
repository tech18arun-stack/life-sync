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
import '../services/startio_ads.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'all';

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
      bottomNavigationBar: const StartioBanner(),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, child) {
          return CustomScrollView(
            slivers: [
              // Modern App Bar with Gradient
              _buildModernAppBar(context, provider),

              // Stats Cards
              SliverToBoxAdapter(child: _buildStatsSection(context, provider)),

              // Filter Chips
              SliverToBoxAdapter(child: _buildFilterChips(context)),

              // Tab Bar
              SliverToBoxAdapter(child: _buildModernTabBar(context)),

              // Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActiveReminders(context, provider),
                    _buildCompletedReminders(context, provider),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildModernFAB(context),
    );
  }

  Widget _buildModernAppBar(BuildContext context, ReminderProvider provider) {
    final totalPending = provider.getPendingReminders().length;
    final overdueCount = provider.getOverdueReminders().length;

    return SliverAppBar(
      expandedHeight: 180,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
                AppTheme.accentColor,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.bell,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Reminders',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '$totalPending pending${overdueCount > 0 ? ' • $overdueCount overdue' : ''}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.wandMagicSparkles,
              color: Colors.white,
              size: 18,
            ),
          ),
          tooltip: 'AI Suggestions',
          onPressed: () => _showAISuggestions(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context, ReminderProvider provider) {
    final pendingReminders = provider.getPendingReminders();
    final overdueReminders = provider.getOverdueReminders();
    final completedThisMonth = provider.reminders.where((r) {
      if (!r.isPaid || r.paidDate == null) return false;
      final now = DateTime.now();
      return r.paidDate!.month == now.month && r.paidDate!.year == now.year;
    }).length;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              'Pending',
              pendingReminders.length.toString(),
              FontAwesomeIcons.clock,
              AppTheme.warningColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Overdue',
              overdueReminders.length.toString(),
              FontAwesomeIcons.triangleExclamation,
              AppTheme.errorColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              context,
              'Done',
              completedThisMonth.toString(),
              FontAwesomeIcons.circleCheck,
              AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context) {
    final filters = [
      {'key': 'all', 'label': 'All', 'icon': FontAwesomeIcons.list},
      {
        'key': 'bill',
        'label': 'Bills',
        'icon': FontAwesomeIcons.fileInvoiceDollar,
      },
      {'key': 'emi', 'label': 'EMI', 'icon': FontAwesomeIcons.buildingColumns},
      {
        'key': 'recharge',
        'label': 'Recharge',
        'icon': FontAwesomeIcons.mobileScreen,
      },
      {
        'key': 'subscription',
        'label': 'Subscriptions',
        'icon': FontAwesomeIcons.rotate,
      },
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FaIcon(
                      filter['icon'] as IconData,
                      size: 12,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key'] as String;
                  });
                },
                selectedColor: AppTheme.primaryColor,
                backgroundColor: Theme.of(context).cardColor,
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                side: BorderSide(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Theme.of(context).dividerColor,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildModernTabBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient,
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppTheme.textSecondary,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Active'),
          Tab(text: 'Completed'),
        ],
      ),
    );
  }

  Widget _buildActiveReminders(
    BuildContext context,
    ReminderProvider provider,
  ) {
    var pendingReminders = provider.getPendingReminders();
    final overdueReminders = provider.getOverdueReminders();
    final upcomingReminders = provider.getUpcomingReminders();

    // Apply filter
    if (_selectedFilter != 'all') {
      pendingReminders = pendingReminders
          .where((r) => r.type.toLowerCase() == _selectedFilter)
          .toList();
    }

    if (pendingReminders.isEmpty) {
      return _buildEmptyState(
        context,
        FontAwesomeIcons.bellSlash,
        'No active reminders',
        'Tap + to add a new reminder',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      children: [
        if (overdueReminders.isNotEmpty) ...[
          _buildSectionHeader(context, 'Overdue', AppTheme.errorColor),
          const SizedBox(height: 12),
          ...overdueReminders.map(
            (r) =>
                _buildModernReminderCard(context, r, provider, isOverdue: true),
          ),
          const SizedBox(height: 24),
        ],
        if (upcomingReminders.isNotEmpty) ...[
          _buildSectionHeader(context, 'Upcoming', AppTheme.primaryColor),
          const SizedBox(height: 12),
          ...upcomingReminders.map(
            (r) => _buildModernReminderCard(context, r, provider),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildModernReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider, {
    bool isOverdue = false,
  }) {
    final daysUntilDue = reminder.dueDate.difference(DateTime.now()).inDays;
    final color = isOverdue
        ? AppTheme.errorColor
        : daysUntilDue <= 3
        ? AppTheme.warningColor
        : AppTheme.primaryColor;

    return Dismissible(
      key: Key(reminder.id ?? ''),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      onDismissed: (direction) {
        provider.deleteReminder(reminder.id ?? '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Reminder deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOverdue
                ? AppTheme.errorColor.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isOverdue
                  ? AppTheme.errorColor.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AddReminderDialog(reminder: reminder),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: FaIcon(
                      _getIconForType(reminder.type),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reminder.title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.calendar,
                              size: 12,
                              color: isOverdue
                                  ? AppTheme.errorColor
                                  : AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat(
                                'MMM d, yyyy',
                              ).format(reminder.dueDate),
                              style: TextStyle(
                                color: isOverdue
                                    ? AppTheme.errorColor
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: isOverdue
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                            if (reminder.isRecurring) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    FaIcon(
                                      FontAwesomeIcons.rotate,
                                      size: 10,
                                      color: AppTheme.accentColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      reminder.recurringType ?? 'Recurring',
                                      style: TextStyle(
                                        color: AppTheme.accentColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (reminder.amount != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '₹${reminder.amount!.toStringAsFixed(0)}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Actions
                  Column(
                    children: [
                      _buildActionButton(
                        context,
                        FontAwesomeIcons.check,
                        AppTheme.successColor,
                        () => _showCompleteDialog(context, reminder, provider),
                        'Done',
                      ),
                      const SizedBox(height: 8),
                      _buildActionButton(
                        context,
                        FontAwesomeIcons.clockRotateLeft,
                        AppTheme.textSecondary,
                        () => _showSnoozeDialog(context, reminder, provider),
                        'Snooze',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FaIcon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildCompletedReminders(
    BuildContext context,
    ReminderProvider provider,
  ) {
    var completedReminders = provider.reminders.where((r) => r.isPaid).toList();
    completedReminders.sort((a, b) {
      final dateA = a.paidDate ?? a.dueDate;
      final dateB = b.paidDate ?? b.dueDate;
      return dateB.compareTo(dateA);
    });

    if (completedReminders.isEmpty) {
      return _buildEmptyState(
        context,
        FontAwesomeIcons.circleCheck,
        'No completed reminders',
        'Complete a reminder to see it here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      itemCount: completedReminders.length,
      itemBuilder: (context, index) {
        final reminder = completedReminders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.circleCheck,
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
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid: ${reminder.paidDate != null ? DateFormat('MMM d, yyyy').format(reminder.paidDate!) : 'Unknown'}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      if (reminder.amount != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '₹${reminder.amount!.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _reworkReminder(context, reminder, provider),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.warningColor,
                  ),
                  child: const Text('Rework'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: FaIcon(
              icon,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        heroTag: 'add_reminder_fab',
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddReminderDialog(),
          );
          await StartIOAds.showInterstitial();
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
        label: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // Dialog Methods (keeping existing logic)
  void _showSnoozeDialog(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Snooze Reminder',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildSnoozeOption(
              context,
              'Tomorrow',
              const Duration(days: 1),
              reminder,
              provider,
            ),
            _buildSnoozeOption(
              context,
              'In 3 Days',
              const Duration(days: 3),
              reminder,
              provider,
            ),
            _buildSnoozeOption(
              context,
              'Next Week',
              const Duration(days: 7),
              reminder,
              provider,
            ),
            _buildSnoozeOption(
              context,
              'Next Month',
              const Duration(days: 30),
              reminder,
              provider,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSnoozeOption(
    BuildContext context,
    String label,
    Duration duration,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    return ListTile(
      onTap: () {
        _snooze(context, reminder, provider, duration);
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: FaIcon(
          FontAwesomeIcons.clockRotateLeft,
          color: AppTheme.primaryColor,
          size: 18,
        ),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      trailing: const Icon(Icons.chevron_right),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  void _snooze(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
    Duration duration,
  ) {
    final newDate = reminder.dueDate.add(duration);
    final updatedReminder = reminder.copyWith(dueDate: newDate);
    provider.updateReminder(updatedReminder);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Snoozed until ${DateFormat('MMM d').format(newDate)}'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(
                FontAwesomeIcons.circleCheck,
                color: AppTheme.successColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Complete Reminder'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mark "${reminder.title}" as complete?'),
            if (reminder.amount != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.indianRupeeSign,
                        size: 16,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        reminder.amount!.toStringAsFixed(2),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeWithExpense(context, reminder, provider);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.successColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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

    if (reminder.amount != null && reminder.amount! > 0) {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );

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
            'Completed! Expense of ₹${reminder.amount!.toStringAsFixed(0)} added',
          ),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Reminder marked as complete'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }

    final updatedReminder = reminder.copyWith(
      isPaid: true,
      paidDate: DateTime.now(),
      linkedExpenseId: expenseId,
    );
    provider.updateReminder(updatedReminder);
    // Show ad after completion
    StartIOAds.showInterstitial();
  }

  void _reworkReminder(
    BuildContext context,
    Reminder reminder,
    ReminderProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
    if (reminder.linkedExpenseId != null) {
      final financialManager = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );
      financialManager.deleteExpense(reminder.linkedExpenseId!);
    }

    final updatedReminder = reminder.copyWith(
      isPaid: false,
      paidDate: null,
      linkedExpenseId: null,
    );
    provider.updateReminder(updatedReminder);
    // Show ad after rework
    StartIOAds.showInterstitial();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder moved to active list'),
        backgroundColor: AppTheme.warningColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      case 'insurance':
        return FontAwesomeIcons.shieldHalved;
      case 'rent':
        return FontAwesomeIcons.house;
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

    final aiStatus = await geminiService.getAIStatus();
    if (!aiStatus['ready']) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'AI features are not enabled. Please check settings.',
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
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
        Navigator.pop(context);
        _showSuggestionsDialog(context, suggestions);
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get suggestions: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'AI Suggestions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          FaIcon(
                            FontAwesomeIcons.lightbulb,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Based on your spending history',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      suggestions,
                      style: const TextStyle(fontSize: 16, height: 1.6),
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
