import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import '../utils/app_theme.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
      appBar: AppBar(
        title: const Text('Tasks & To-Do'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartLine),
            tooltip: 'Statistics',
            onPressed: () => _showStatistics(context, taskProvider),
          ),
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
            onSelected: (value) {
              if (value == 'clearCompleted') {
                _clearCompletedTasks(taskProvider);
              } else if (value == 'sortBy') {
                _showSortOptions();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sortBy',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.arrowDownWideShort, size: 16),
                    SizedBox(width: 12),
                    Text('Sort By'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clearCompleted',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.trash, size: 16),
                    SizedBox(width: 12),
                    Text('Clear Completed'),
                  ],
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
              icon: const FaIcon(FontAwesomeIcons.listCheck, size: 18),
              text: 'All (${taskProvider.tasks.length})',
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.clock, size: 18),
              text: 'Pending (${taskProvider.pendingTasks.length})',
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.circleCheck, size: 18),
              text: 'Done (${taskProvider.completedTasks.length})',
            ),
            Tab(
              icon: const FaIcon(FontAwesomeIcons.calendarDay, size: 18),
              text: 'Today',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).cardColor,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _searchQuery = ''),
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
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
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddTaskDialog(),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Task'),
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
            child: FilterChip(
              label: Text(priority),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPriority = priority);
              },
              selectedColor: AppTheme.primaryColor.withOpacity(0.2),
              checkmarkColor: AppTheme.primaryColor,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Progress', style: Theme.of(context).textTheme.titleSmall),
              Text(
                '$completed / $total completed',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation(AppTheme.successColor),
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% Complete',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.successColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(List<Task> tasks, TaskProvider provider) {
    // Filter by search and priority
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

    // Sort tasks
    _sortTasks(filteredTasks);

    if (filteredTasks.isEmpty) {
      return _buildEmptyState();
    }

    // Group tasks by category
    final groupedTasks = <String, List<Task>>{};
    for (final task in filteredTasks) {
      groupedTasks.putIfAbsent(task.category, () => []).add(task);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...groupedTasks.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCategoryHeader(entry.key, entry.value.length),
                ...entry.value.map((task) => TaskItem(task: task)),
                const SizedBox(height: 16),
              ],
            );
          }),
          const SizedBox(height: 80),
        ],
      ),
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
            _buildSectionHeader('Overdue', overdue.length, AppTheme.errorColor),
            ...overdue.map((task) => TaskItem(task: task)),
            const SizedBox(height: 16),
          ],
          if (pending.isNotEmpty) ...[
            _buildSectionHeader(
              'Due Today',
              pending.length,
              AppTheme.warningColor,
            ),
            ...pending.map((task) => TaskItem(task: task)),
            const SizedBox(height: 16),
          ],
          if (completed.isNotEmpty) ...[
            _buildSectionHeader(
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
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            category.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FaIcon(
              title == 'Overdue'
                  ? FontAwesomeIcons.exclamation
                  : title == 'Due Today'
                  ? FontAwesomeIcons.clock
                  : FontAwesomeIcons.check,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
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
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            message ??
                (_searchQuery.isNotEmpty
                    ? 'No matching tasks'
                    : 'No tasks yet'),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'Add a task to get started',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort By', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...['Date', 'Priority', 'Name'].map((option) {
              return RadioListTile<String>(
                title: Text(option),
                value: option,
                groupValue: _sortBy,
                onChanged: (value) {
                  setState(() => _sortBy = value!);
                  Navigator.pop(context);
                },
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
        title: const Text('Clear Completed Tasks?'),
        content: Text(
          'This will delete ${provider.completedTasks.length} completed tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              for (var task in provider.completedTasks.toList()) {
                provider.deleteTask(task.id ?? '');
              }
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Completed tasks cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
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
        title: const Row(
          children: [
            FaIcon(FontAwesomeIcons.chartLine, size: 20),
            SizedBox(width: 12),
            Text('Task Statistics'),
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
              FontAwesomeIcons.exclamation,
              AppTheme.errorColor,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FaIcon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
