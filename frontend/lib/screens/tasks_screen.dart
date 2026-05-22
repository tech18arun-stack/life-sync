import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../providers/task_provider.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_dialog.dart';
import '../services/startio_ads.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedPriority = 'All';
  String _sortBy = 'Date';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const StartioBanner(),
      appBar: AppBar(
        title: Text(
          'Tasks & To-Do',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartLine, size: 20),
            tooltip: 'Statistics',
            onPressed: () => _showStatistics(context, taskProvider),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical, size: 20),
            onSelected: (value) {
              if (value == 'clearCompleted') {
                _clearCompletedTasks(taskProvider);
              } else if (value == 'sortBy') {
                _showSortOptions();
              }
            },
            color: Theme.of(context).cardColor,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'sortBy',
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.arrowDownWideShort, size: 16),
                    const SizedBox(width: 12),
                    Text('Sort By', style: GoogleFonts.inter()),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clearCompleted',
                child: Row(
                  children: [
                    const FaIcon(FontAwesomeIcons.trash, size: 16),
                    const SizedBox(width: 12),
                    Text('Clear Completed', style: GoogleFonts.inter()),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
          unselectedLabelStyle: GoogleFonts.inter(),
          indicatorColor: AppTheme.primaryColor,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'All (${taskProvider.tasks.length})'),
            Tab(text: 'Pending (${taskProvider.pendingTasks.length})'),
            Tab(text: 'Done (${taskProvider.completedTasks.length})'),
            const Tab(text: 'Today'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.inter(),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    hintStyle: GoogleFonts.inter(color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.grey),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                _buildPriorityFilter(),
              ],
            ),
          ),

          // Progress Bar
          _buildProgressBar(taskProvider),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList(taskProvider.tasks, taskProvider),
                _buildTaskList(taskProvider.pendingTasks, taskProvider),
                _buildTaskList(taskProvider.completedTasks, taskProvider),
                _buildTodayTasks(taskProvider),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_task_fab',
        onPressed: () async {
          await showDialog(
            context: context,
            builder: (context) => const AddTaskDialog(),
          );
          await StartIOAds.showInterstitial(context);
        },
        backgroundColor: AppTheme.primaryColor,
        icon: const FaIcon(
          FontAwesomeIcons.plus,
          color: Colors.white,
          size: 18,
        ),
        label: Text(
          'Add Task',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityFilter() {
    return Row(
      children: ['All', 'High', 'Medium', 'Low'].map((priority) {
        final isSelected = _selectedPriority == priority;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedPriority = priority),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? null
                      : Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                ),
                child: Text(
                  priority,
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProgressBar(TaskProvider provider) {
    final total = provider.tasks.length;
    final completed = provider.completedTasks.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text(
                '$completed / $total',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskProvider provider) {
    // Filter
    final filteredTasks = tasks.where((task) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          task.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (task.description?.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ??
              false);
      final matchesPriority =
          _selectedPriority == 'All' ||
          task.priority.toLowerCase() == _selectedPriority.toLowerCase();
      return matchesSearch && matchesPriority;
    }).toList();

    // Sort
    _sortTasks(filteredTasks);

    if (filteredTasks.isEmpty) return _buildEmptyState();

    final groupedTasks = <String, List<Task>>{};
    for (final task in filteredTasks) {
      groupedTasks.putIfAbsent(task.category, () => []).add(task);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedTasks.length + 1, // +1 for extra spacing at bottom
      itemBuilder: (context, index) {
        if (index == groupedTasks.length) return const SizedBox(height: 80);

        final category = groupedTasks.keys.elementAt(index);
        final categoryTasks = groupedTasks[category]!;

        return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(category, categoryTasks.length),
                ...categoryTasks.map((task) => TaskItem(task: task)),
                if (index == 0) ...[
                  const SizedBox(height: 16),
                  const Center(child: StartioMrec()),
                ],
                const SizedBox(height: 16),
              ],
            )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.1, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildTodayTasks(TaskProvider provider) {
    final today = DateTime.now();
    final todayTasks = provider.tasks.where((task) {
      return task.dueDate != null &&
          task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();

    if (todayTasks.isEmpty) {
      return _buildEmptyState(
        message: 'No tasks due today',
        icon: FontAwesomeIcons.calendarCheck,
      );
    }

    final overdue = todayTasks
        .where((t) => !t.isCompleted && t.dueDate!.isBefore(DateTime.now()))
        .toList();
    final pending = todayTasks
        .where((t) => !t.isCompleted && !overdue.contains(t))
        .toList();
    final completed = todayTasks.where((t) => t.isCompleted).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (overdue.isNotEmpty) ...[
            _buildSectionLabel('Overdue', overdue.length, AppTheme.errorColor),
            ...overdue.map((task) => TaskItem(task: task)),
            const SizedBox(height: 16),
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionLabel(
              'Due Today',
              pending.length,
              AppTheme.warningColor,
            ),
            ...pending.map((task) => TaskItem(task: task)),
            const SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionLabel(
              'Completed',
              completed.length,
              AppTheme.successColor,
            ),
            ...completed.map((task) => TaskItem(task: task)),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String category, int count) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            category.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          FaIcon(
            title == 'Overdue'
                ? FontAwesomeIcons.triangleExclamation
                : title == 'Due Today'
                ? FontAwesomeIcons.clock
                : FontAwesomeIcons.check,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({String? message, IconData? icon}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(
            icon ?? FontAwesomeIcons.clipboardCheck,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 20),
          Text(
            message ??
                (_searchQuery.isNotEmpty
                    ? 'No matching tasks'
                    : 'No tasks yet'),
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          if (_searchQuery.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Tap + to create a new task',
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  void _sortTasks(List<Task> tasks) {
    switch (_sortBy) {
      case 'Date':
        tasks.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case 'Priority':
        tasks.sort((a, b) {
          const priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
          return (priorityOrder[a.priority.toLowerCase()] ?? 3).compareTo(
            priorityOrder[b.priority.toLowerCase()] ?? 3,
          );
        });
        break;
      case 'Name':
        tasks.sort((a, b) => a.title.compareTo(b.title));
        break;
    }
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['Date', 'Priority', 'Name'].map((option) {
              return ListTile(
                title: Text(option, style: GoogleFonts.inter()),
                trailing: _sortBy == option
                    ? const Icon(Icons.check, color: AppTheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() => _sortBy = option);
                  Navigator.pop(context);
                },
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  void _clearCompletedTasks(TaskProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Completed?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Delete ${provider.completedTasks.length} completed tasks?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter()),
          ),
          ElevatedButton(
            onPressed: () async {
              for (var task in provider.completedTasks.toList()) {
                provider.deleteTask(task.id ?? '');
              }
              // Show high-revenue video ad after major action
              await StartIOAds.showVideoInterstitial(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Completed tasks cleared',
                    style: GoogleFonts.inter(),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: Text('Clear', style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatistics(BuildContext context, TaskProvider provider) {
    final total = provider.tasks.length;
    final completed = provider.completedTasks.length;
    final pending = provider.pendingTasks.length;
    final highPriority = provider.tasks
        .where((t) => t.priority == 'High' && !t.isCompleted)
        .length;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.chartLine, size: 20),
            const SizedBox(width: 12),
            Text(
              'Statistics',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow(
              'Total Tasks',
              '$total',
              FontAwesomeIcons.listCheck,
              AppTheme.primaryColor,
            ),
            _buildStatRow(
              'Completed',
              '$completed',
              FontAwesomeIcons.circleCheck,
              AppTheme.successColor,
            ),
            _buildStatRow(
              'Pending',
              '$pending',
              FontAwesomeIcons.clock,
              AppTheme.warningColor,
            ),
            _buildStatRow(
              'High Priority',
              '$highPriority',
              FontAwesomeIcons.triangleExclamation,
              AppTheme.errorColor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: GoogleFonts.inter())),
          Text(
            value,
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
