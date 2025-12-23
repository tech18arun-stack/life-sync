import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/financial_data_manager.dart';
import '../providers/reminder_provider.dart';
import '../providers/family_event_provider.dart';
import '../utils/app_theme.dart';
import '../models/expense.dart';
import '../models/income.dart';

class FinancialCalendarScreen extends StatefulWidget {
  const FinancialCalendarScreen({super.key});

  @override
  State<FinancialCalendarScreen> createState() =>
      _FinancialCalendarScreenState();
}

class _FinancialCalendarScreenState extends State<FinancialCalendarScreen>
    with SingleTickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  String _viewMode = 'month'; // month, week, agenda
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Financial Calendar'),
        actions: [
          // View mode selector
          PopupMenuButton<String>(
            icon: const FaIcon(FontAwesomeIcons.ellipsisVertical),
            onSelected: (value) {
              setState(() {
                _viewMode = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'month',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.calendar, size: 16),
                    SizedBox(width: 12),
                    Text('Month View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'week',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.calendarWeek, size: 16),
                    SizedBox(width: 12),
                    Text('Week View'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'agenda',
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.list, size: 16),
                    SizedBox(width: 12),
                    Text('Agenda View'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.house),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
            tooltip: 'Today',
          ),
        ],
      ),
      body:
          Consumer3<
            FinancialDataManager,
            ReminderProvider,
            FamilyEventProvider
          >(
            builder:
                (
                  context,
                  financialManager,
                  reminderProvider,
                  eventProvider,
                  child,
                ) {
                  return Column(
                    children: [
                      // Month Statistics Card
                      _buildMonthStatisticsCard(context, financialManager),

                      // Calendar Header with Navigation
                      _buildCalendarHeader(),

                      // View Content
                      Expanded(
                        child: _viewMode == 'month'
                            ? _buildMonthView(
                                financialManager,
                                reminderProvider,
                                eventProvider,
                              )
                            : _viewMode == 'week'
                            ? _buildWeekView(
                                financialManager,
                                reminderProvider,
                                eventProvider,
                              )
                            : _buildAgendaView(
                                financialManager,
                                reminderProvider,
                                eventProvider,
                              ),
                      ),
                    ],
                  );
                },
          ),
    );
  }

  Widget _buildMonthStatisticsCard(
    BuildContext context,
    FinancialDataManager manager,
  ) {
    final monthStart = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final monthEnd = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);

    final monthIncomes = manager.incomes.where((i) {
      return i.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          i.date.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();

    final monthExpenses = manager.expenses.where((e) {
      return e.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
          e.date.isBefore(monthEnd.add(const Duration(days: 1)));
    }).toList();

    final totalIncome = monthIncomes.fold<double>(
      0,
      (sum, i) => sum + i.amount,
    );
    final totalExpense = monthExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final balance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            DateFormat('MMMM yyyy').format(_focusedDay),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                FontAwesomeIcons.arrowTrendUp,
                '₹${totalIncome.toStringAsFixed(0)}',
                'Income',
                AppTheme.successColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                FontAwesomeIcons.arrowTrendDown,
                '₹${totalExpense.toStringAsFixed(0)}',
                'Expenses',
                AppTheme.errorColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.3),
              ),
              _buildStatItem(
                FontAwesomeIcons.wallet,
                '₹${balance.toStringAsFixed(0)}',
                'Balance',
                balance >= 0 ? Colors.white : AppTheme.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FaIcon(
                FontAwesomeIcons.receipt,
                color: Colors.white.withValues(alpha: 0.7),
                size: 12,
              ),
              const SizedBox(width: 8),
              Text(
                '${monthExpenses.length} transactions • ${monthIncomes.length} income sources',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        FaIcon(icon, color: color, size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chevronLeft),
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                    1,
                  );
                } else if (_viewMode == 'week') {
                  _focusedDay = _focusedDay.subtract(const Duration(days: 7));
                }
              });
            },
          ),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _focusedDay,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                setState(() {
                  _focusedDay = picked;
                  _selectedDay = picked;
                });
              }
            },
            child: Row(
              children: [
                Text(
                  _viewMode == 'month'
                      ? DateFormat('MMMM yyyy').format(_focusedDay)
                      : _viewMode == 'week'
                      ? _getWeekRange()
                      : 'All Events',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                const FaIcon(FontAwesomeIcons.calendarDays, size: 16),
              ],
            ),
          ),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chevronRight),
            onPressed: () {
              setState(() {
                if (_viewMode == 'month') {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                    1,
                  );
                } else if (_viewMode == 'week') {
                  _focusedDay = _focusedDay.add(const Duration(days: 7));
                }
              });
            },
          ),
        ],
      ),
    );
  }

  String _getWeekRange() {
    final weekStart = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday - 1),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));
    return '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
  }

  Widget _buildMonthView(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    return Column(
      children: [
        // Weekday headers
        Container(
          color: Theme.of(context).cardColor,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        // Calendar grid
        Expanded(
          child: _buildCalendarGrid(
            financialManager,
            reminderProvider,
            eventProvider,
          ),
        ),
        // Selected day details
        if (_selectedDay != null)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: _buildSelectedDayDetails(
              financialManager,
              reminderProvider,
              eventProvider,
            ),
          ),
      ],
    );
  }

  Widget _buildCalendarGrid(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    final daysInMonth = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    ).day;
    final firstDayOfWeek = DateTime(
      _focusedDay.year,
      _focusedDay.month,
      1,
    ).weekday;
    final today = DateTime.now();

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.8,
      ),
      itemCount: daysInMonth + firstDayOfWeek % 7,
      itemBuilder: (context, index) {
        if (index < firstDayOfWeek % 7) {
          return const SizedBox();
        }

        final day = index - (firstDayOfWeek % 7) + 1;
        final date = DateTime(_focusedDay.year, _focusedDay.month, day);

        final isToday =
            date.year == today.year &&
            date.month == today.month &&
            date.day == today.day;

        final isSelected =
            _selectedDay != null &&
            date.year == _selectedDay!.year &&
            date.month == _selectedDay!.month &&
            date.day == _selectedDay!.day;

        // Get data for this day
        final dayExpenses = financialManager.expenses
            .where(
              (e) =>
                  e.date.year == date.year &&
                  e.date.month == date.month &&
                  e.date.day == date.day,
            )
            .toList();

        final dayIncomes = financialManager.incomes
            .where(
              (i) =>
                  i.date.year == date.year &&
                  i.date.month == date.month &&
                  i.date.day == date.day,
            )
            .toList();

        final dayReminders = reminderProvider.reminders
            .where(
              (r) =>
                  r.dueDate.year == date.year &&
                  r.dueDate.month == date.month &&
                  r.dueDate.day == date.day,
            )
            .toList();

        final dayEvents = eventProvider.events.where((e) {
          if (e.startDate.year == date.year &&
              e.startDate.month == date.month &&
              e.startDate.day == date.day) {
            return true;
          }
          if (e.endDate != null) {
            return date.isAfter(e.startDate) && date.isBefore(e.endDate!);
          }
          return false;
        }).toList();

        final totalExpense = dayExpenses.fold<double>(
          0,
          (sum, e) => sum + e.amount,
        );
        final totalIncome = dayIncomes.fold<double>(
          0,
          (sum, i) => sum + i.amount,
        );

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryColor
                  : isToday
                  ? AppTheme.accentColor.withValues(alpha: 0.2)
                  : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isToday
                    ? AppTheme.accentColor
                    : isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).dividerColor,
                width: isToday || isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : isToday
                        ? AppTheme.accentColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (dayIncomes.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppTheme.successColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (dayExpenses.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (dayReminders.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: const BoxDecoration(
                          color: AppTheme.warningColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (dayEvents.isNotEmpty)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade400,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                if (totalExpense > 0 || totalIncome > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '₹${(totalIncome - totalExpense).abs().toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.9)
                          : (totalIncome - totalExpense) >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeekView(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    final weekStart = _focusedDay.subtract(
      Duration(days: _focusedDay.weekday - 1),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 7,
      itemBuilder: (context, index) {
        final date = weekStart.add(Duration(days: index));
        final isToday =
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        final dayExpenses = financialManager.expenses
            .where(
              (e) =>
                  e.date.year == date.year &&
                  e.date.month == date.month &&
                  e.date.day == date.day,
            )
            .toList();

        final dayIncomes = financialManager.incomes
            .where(
              (i) =>
                  i.date.year == date.year &&
                  i.date.month == date.month &&
                  i.date.day == date.day,
            )
            .toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isToday
                ? AppTheme.accentColor.withValues(alpha: 0.1)
                : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isToday
                  ? AppTheme.accentColor
                  : Theme.of(context).dividerColor,
              width: isToday ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    DateFormat('EEEE, MMM d').format(date),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isToday ? AppTheme.accentColor : null,
                    ),
                  ),
                  if (isToday)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildWeekDayStat(
                      'Income',
                      dayIncomes.fold<double>(0, (sum, i) => sum + i.amount),
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildWeekDayStat(
                      'Expense',
                      dayExpenses.fold<double>(0, (sum, e) => sum + e.amount),
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              if (dayExpenses.isNotEmpty || dayIncomes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  '${dayExpenses.length + dayIncomes.length} transactions',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekDayStat(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaView(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    // Get all upcoming transactions and events
    final upcomingItems = <Map<String, dynamic>>[];

    // Add expenses
    for (final expense in financialManager.expenses) {
      upcomingItems.add({
        'type': 'expense',
        'date': expense.date,
        'data': expense,
      });
    }

    // Add incomes
    for (final income in financialManager.incomes) {
      upcomingItems.add({
        'type': 'income',
        'date': income.date,
        'data': income,
      });
    }

    // Add reminders
    for (final reminder in reminderProvider.reminders) {
      upcomingItems.add({
        'type': 'reminder',
        'date': reminder.dueDate,
        'data': reminder,
      });
    }

    // Add events
    for (final event in eventProvider.events) {
      upcomingItems.add({
        'type': 'event',
        'date': event.startDate,
        'data': event,
      });
    }

    // Sort by date
    upcomingItems.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    // Group by date
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final item in upcomingItems) {
      final dateKey = DateFormat('yyyy-MM-dd').format(item['date'] as DateTime);
      groupedItems[dateKey] = groupedItems[dateKey] ?? [];
      groupedItems[dateKey]!.add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final dateKey = groupedItems.keys.elementAt(index);
        final items = groupedItems[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                DateFormat('EEEE, MMMM d, yyyy').format(date),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            ...items.map((item) => _buildAgendaItem(context, item)),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAgendaItem(BuildContext context, Map<String, dynamic> item) {
    final type = item['type'] as String;

    IconData icon;
    Color color;
    String title;
    String subtitle;
    String amount = '';

    switch (type) {
      case 'expense':
        final expense = item['data'] as Expense;
        icon = FontAwesomeIcons.arrowTrendDown;
        color = AppTheme.errorColor;
        title = expense.title;
        subtitle = expense.category;
        amount = '-₹${expense.amount.toStringAsFixed(0)}';
        break;
      case 'income':
        final income = item['data'] as Income;
        icon = FontAwesomeIcons.arrowTrendUp;
        color = AppTheme.successColor;
        title = income.title;
        subtitle = income.source;
        amount = '+₹${income.amount.toStringAsFixed(0)}';
        break;
      case 'reminder':
        icon = FontAwesomeIcons.bell;
        color = AppTheme.warningColor;
        title = item['data'].title;
        subtitle = 'Reminder';
        if (item['data'].amount != null) {
          amount = '₹${item['data'].amount!.toStringAsFixed(0)}';
        }
        break;
      case 'event':
        icon = FontAwesomeIcons.calendarDay;
        color = Colors.purple;
        title = item['data'].title;
        subtitle = 'Event';
        break;
      default:
        icon = FontAwesomeIcons.circle;
        color = Colors.grey;
        title = 'Unknown';
        subtitle = '';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (amount.isNotEmpty)
            Text(
              amount,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayDetails(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    if (_selectedDay == null) return const SizedBox();

    final dayExpenses = financialManager.expenses.where((e) {
      return e.date.year == _selectedDay!.year &&
          e.date.month == _selectedDay!.month &&
          e.date.day == _selectedDay!.day;
    }).toList();

    final dayIncomes = financialManager.incomes.where((i) {
      return i.date.year == _selectedDay!.year &&
          i.date.month == _selectedDay!.month &&
          i.date.day == _selectedDay!.day;
    }).toList();

    final dayReminders = reminderProvider.reminders.where((r) {
      return r.dueDate.year == _selectedDay!.year &&
          r.dueDate.month == _selectedDay!.month &&
          r.dueDate.day == _selectedDay!.day;
    }).toList();

    final dayEvents = eventProvider.events.where((e) {
      final selectedDate = _selectedDay!;
      if (e.startDate.year == selectedDate.year &&
          e.startDate.month == selectedDate.month &&
          e.startDate.day == selectedDate.day) {
        return true;
      }
      if (e.endDate != null) {
        return selectedDate.isAfter(e.startDate) &&
            selectedDate.isBefore(e.endDate!);
      }
      return false;
    }).toList();

    final totalIncome = dayIncomes.fold<double>(0, (sum, i) => sum + i.amount);
    final totalExpense = dayExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(_selectedDay!),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: (totalIncome - totalExpense) >= 0
                    ? AppTheme.successColor.withValues(alpha: 0.1)
                    : AppTheme.errorColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '₹${(totalIncome - totalExpense).toStringAsFixed(0)}',
                style: TextStyle(
                  color: (totalIncome - totalExpense) >= 0
                      ? AppTheme.successColor
                      : AppTheme.errorColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (dayExpenses.isEmpty &&
            dayIncomes.isEmpty &&
            dayReminders.isEmpty &&
            dayEvents.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'No activities for this day',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (dayIncomes.isNotEmpty)
                _buildQuickStat(
                  '${dayIncomes.length} Income',
                  AppTheme.successColor,
                ),
              if (dayExpenses.isNotEmpty)
                _buildQuickStat(
                  '${dayExpenses.length} Expenses',
                  AppTheme.errorColor,
                ),
              if (dayReminders.isNotEmpty)
                _buildQuickStat(
                  '${dayReminders.length} Reminders',
                  AppTheme.warningColor,
                ),
              if (dayEvents.isNotEmpty)
                _buildQuickStat('${dayEvents.length} Events', Colors.purple),
            ],
          ),
      ],
    );
  }

  Widget _buildQuickStat(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
