import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../providers/reminder_provider.dart';
import '../providers/family_event_provider.dart';
import '../utils/app_theme.dart';
import '../models/expense.dart';
import '../models/income.dart';
import '../widgets/add_expense_dialog.dart';
import '../widgets/add_income_dialog.dart';
import '../services/startio_ads.dart';

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
  String _viewMode = 'month';
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  return CustomScrollView(
                    slivers: [
                      // Modern App Bar with Month Stats
                      _buildModernAppBar(context, financialManager),

                      // Quick Stats Row
                      SliverToBoxAdapter(
                        child: _buildQuickStatsRow(context, financialManager),
                      ),

                      // View Mode Selector
                      SliverToBoxAdapter(
                        child: _buildViewModeSelector(context),
                      ),

                      // Calendar Content
                      SliverFillRemaining(
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
      floatingActionButton: _buildModernFAB(context),
    );
  }

  Widget _buildModernAppBar(
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

    return SliverAppBar(
      expandedHeight: 220,
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
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                              1,
                            );
                          });
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.chevronLeft,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
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
                        child: Column(
                          children: [
                            Text(
                              DateFormat('MMMM').format(_focusedDay),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy').format(_focusedDay),
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                              1,
                            );
                          });
                        },
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const FaIcon(
                            FontAwesomeIcons.chevronRight,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildHeaderStat(
                          FontAwesomeIcons.arrowUp,
                          '₹${_formatAmount(totalIncome)}',
                          'Income',
                          AppTheme.successColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildHeaderStat(
                          FontAwesomeIcons.arrowDown,
                          '₹${_formatAmount(totalExpense)}',
                          'Expense',
                          AppTheme.errorColor,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                        _buildHeaderStat(
                          FontAwesomeIcons.wallet,
                          '₹${_formatAmount(balance.abs())}',
                          balance >= 0 ? 'Saved' : 'Over',
                          balance >= 0 ? Colors.white : AppTheme.errorColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = DateTime.now();
            });
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.house,
              color: Colors.white,
              size: 16,
            ),
          ),
          tooltip: 'Today',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderStat(
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          children: [
            FaIcon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) {
      return '${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildQuickStatsRow(
    BuildContext context,
    FinancialDataManager manager,
  ) {
    final today = DateTime.now();
    final todayExpenses = manager.expenses
        .where(
          (e) =>
              e.date.year == today.year &&
              e.date.month == today.month &&
              e.date.day == today.day,
        )
        .toList();

    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final weekExpenses = manager.expenses
        .where(
          (e) =>
              e.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
              e.date.isBefore(today.add(const Duration(days: 1))),
        )
        .toList();

    final todayTotal = todayExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final weekTotal = weekExpenses.fold<double>(0, (sum, e) => sum + e.amount);

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickStatCard(
              context,
              'Today',
              '₹${_formatAmount(todayTotal)}',
              FontAwesomeIcons.calendarDay,
              AppTheme.primaryColor,
              '${todayExpenses.length} txn',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildQuickStatCard(
              context,
              'This Week',
              '₹${_formatAmount(weekTotal)}',
              FontAwesomeIcons.calendarWeek,
              AppTheme.accentColor,
              '${weekExpenses.length} txn',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    var theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewModeSelector(BuildContext context) {
    final modes = [
      {'key': 'month', 'label': 'Month', 'icon': FontAwesomeIcons.calendar},
      {'key': 'week', 'label': 'Week', 'icon': FontAwesomeIcons.calendarWeek},
      {'key': 'agenda', 'label': 'Agenda', 'icon': FontAwesomeIcons.list},
    ];

    var theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: modes.map((mode) {
          final isSelected = _viewMode == mode['key'];
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _viewMode = mode['key'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      mode['icon'] as IconData,
                      size: 14,
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mode['label'] as String,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? Colors.white
                            : AppTheme.textSecondary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          child: Row(
            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((day) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textSecondary,
                      fontSize: 13,
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
          _buildSelectedDaySheet(
            financialManager,
            reminderProvider,
            eventProvider,
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
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.9,
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

        final hasData =
            dayExpenses.isNotEmpty ||
            dayIncomes.isNotEmpty ||
            dayReminders.isNotEmpty;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDay = date;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? AppTheme.primaryGradient
                  : isToday
                  ? LinearGradient(
                      colors: [
                        AppTheme.accentColor.withValues(alpha: 0.2),
                        AppTheme.accentColor.withValues(alpha: 0.1),
                      ],
                    )
                  : null,
              color: isSelected || isToday ? null : Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isToday && !isSelected
                    ? AppTheme.accentColor
                    : isSelected
                    ? Colors.transparent
                    : Theme.of(context).dividerColor.withValues(alpha: 0.5),
                width: isToday ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$day',
                  style: GoogleFonts.inter(
                    color: isSelected
                        ? Colors.white
                        : isToday
                        ? AppTheme.accentColor
                        : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isToday || isSelected
                        ? FontWeight.bold
                        : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (hasData) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (dayIncomes.isNotEmpty)
                        _buildDot(
                          isSelected ? Colors.white : AppTheme.successColor,
                        ),
                      if (dayExpenses.isNotEmpty)
                        _buildDot(
                          isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : AppTheme.errorColor,
                        ),
                      if (dayReminders.isNotEmpty)
                        _buildDot(
                          isSelected
                              ? Colors.white.withValues(alpha: 0.6)
                              : AppTheme.warningColor,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDot(Color color) {
    return Container(
      width: 5,
      height: 5,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSelectedDaySheet(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    if (_selectedDay == null) {
      return const SizedBox();
    }

    final dayExpenses = financialManager.expenses
        .where(
          (e) =>
              e.date.year == _selectedDay!.year &&
              e.date.month == _selectedDay!.month &&
              e.date.day == _selectedDay!.day,
        )
        .toList();

    final dayIncomes = financialManager.incomes
        .where(
          (i) =>
              i.date.year == _selectedDay!.year &&
              i.date.month == _selectedDay!.month &&
              i.date.day == _selectedDay!.day,
        )
        .toList();

    final dayReminders = reminderProvider.reminders
        .where(
          (r) =>
              r.dueDate.year == _selectedDay!.year &&
              r.dueDate.month == _selectedDay!.month &&
              r.dueDate.day == _selectedDay!.day &&
              !r.isPaid,
        )
        .toList();

    final totalExpense = dayExpenses.fold<double>(
      0,
      (sum, e) => sum + e.amount,
    );
    final totalIncome = dayIncomes.fold<double>(0, (sum, i) => sum + i.amount);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE').format(_selectedDay!),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                      ),
                    ),
                    Text(
                      DateFormat('MMMM d, yyyy').format(_selectedDay!),
                      style: GoogleFonts.inter(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (totalIncome > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.arrowUp,
                              size: 10,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${totalIncome.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: AppTheme.successColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (totalIncome > 0 && totalExpense > 0)
                      const SizedBox(width: 8),
                    if (totalExpense > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.arrowDown,
                              size: 10,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '₹${totalExpense.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                color: AppTheme.errorColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
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
          // Transaction list
          Expanded(
            child:
                (dayExpenses.isEmpty &&
                    dayIncomes.isEmpty &&
                    dayReminders.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FaIcon(
                          FontAwesomeIcons.receipt,
                          size: 32,
                          color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No transactions',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    children: [
                      ...dayIncomes.map(
                        (income) => _buildMiniTransactionCard(
                          income.source,
                          '₹${income.amount.toStringAsFixed(0)}',
                          FontAwesomeIcons.arrowUp,
                          AppTheme.successColor,
                        ),
                      ),
                      ...dayExpenses.map(
                        (expense) => _buildMiniTransactionCard(
                          expense.description,
                          '₹${expense.amount.toStringAsFixed(0)}',
                          FontAwesomeIcons.arrowDown,
                          AppTheme.errorColor,
                        ),
                      ),
                      ...dayReminders.map(
                        (reminder) => _buildMiniTransactionCard(
                          reminder.title,
                          reminder.amount != null
                              ? '₹${reminder.amount!.toStringAsFixed(0)}'
                              : 'Pending',
                          FontAwesomeIcons.bell,
                          AppTheme.warningColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTransactionCard(
    String title,
    String amount,
    IconData icon,
    Color color,
  ) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12, bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FaIcon(icon, size: 12, color: color),
              const Spacer(),
              Text(
                amount,
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(20),
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

        final totalExpense = dayExpenses.fold<double>(
          0,
          (sum, e) => sum + e.amount,
        );
        final totalIncome = dayIncomes.fold<double>(
          0,
          (sum, i) => sum + i.amount,
        );

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: isToday
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.1),
                      AppTheme.accentColor.withValues(alpha: 0.05),
                    ],
                  )
                : null,
            color: isToday ? null : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isToday
                  ? AppTheme.primaryColor
                  : Theme.of(context).dividerColor.withValues(alpha: 0.5),
              width: isToday ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Date column
                SizedBox(
                  width: 50,
                  child: Column(
                    children: [
                      Text(
                        DateFormat('EEE').format(date),
                        style: GoogleFonts.inter(
                          color: isToday
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${date.day}',
                        style: GoogleFonts.inter(
                          color: isToday ? AppTheme.primaryColor : null,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Stats
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.arrowUp,
                                    size: 10,
                                    color: AppTheme.successColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Income',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.successColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${totalIncome.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  FaIcon(
                                    FontAwesomeIcons.arrowDown,
                                    size: 10,
                                    color: AppTheme.errorColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Expense',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.errorColor,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${totalExpense.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(
                                  color: AppTheme.errorColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isToday) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'TODAY',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildAgendaView(
    FinancialDataManager financialManager,
    ReminderProvider reminderProvider,
    FamilyEventProvider eventProvider,
  ) {
    final allTransactions = <Map<String, dynamic>>[];

    // Add expenses
    for (final expense in financialManager.expenses) {
      allTransactions.add({
        'type': 'expense',
        'date': expense.date,
        'title': expense.description,
        'amount': expense.amount,
        'category': expense.category,
        'data': expense,
      });
    }

    // Add incomes
    for (final income in financialManager.incomes) {
      allTransactions.add({
        'type': 'income',
        'date': income.date,
        'title': income.source,
        'amount': income.amount,
        'category': income.source, // Use source as category
        'data': income,
      });
    }

    // Sort by date descending
    allTransactions.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );

    // Group by date
    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (final transaction in allTransactions) {
      final dateKey = DateFormat(
        'yyyy-MM-dd',
      ).format(transaction['date'] as DateTime);
      groupedTransactions[dateKey] ??= [];
      groupedTransactions[dateKey]!.add(transaction);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final dateKey = sortedDates[index];
        final date = DateTime.parse(dateKey);
        final transactions = groupedTransactions[dateKey]!;

        final isToday =
            date.year == DateTime.now().year &&
            date.month == DateTime.now().month &&
            date.day == DateTime.now().day;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: isToday ? AppTheme.primaryGradient : null,
                      color: isToday ? null : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isToday
                          ? 'Today'
                          : DateFormat('MMM d, yyyy').format(date),
                      style: GoogleFonts.inter(
                        color: isToday ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('EEEE').format(date),
                    style: GoogleFonts.inter(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
            // Transactions for this date
            ...transactions.map(
              (transaction) => _buildAgendaTransactionCard(transaction),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildAgendaTransactionCard(Map<String, dynamic> transaction) {
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;
    final icon = isIncome
        ? FontAwesomeIcons.arrowUp
        : FontAwesomeIcons.arrowDown;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isIncome) {
              showDialog(
                context: context,
                builder: (context) =>
                    AddIncomeDialog(income: transaction['data'] as Income),
              );
            } else {
              showDialog(
                context: context,
                builder: (context) =>
                    AddExpenseDialog(expense: transaction['data'] as Expense),
              );
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(icon, color: color, size: 14),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['title'] as String,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        transaction['category'] as String,
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isIncome ? '+' : '-'}₹${(transaction['amount'] as double).toStringAsFixed(0)}',
                  style: GoogleFonts.inter(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
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
        heroTag: 'calendar_fab',
        onPressed: () {
          _showQuickAddBottomSheet(context);
        },
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const FaIcon(FontAwesomeIcons.plus, size: 18),
        label: Text(
          'Add',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  void _showQuickAddBottomSheet(BuildContext context) {
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
              'Quick Add',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAddOption(
                    context,
                    'Expense',
                    FontAwesomeIcons.arrowDown,
                    AppTheme.errorColor,
                    () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const AddExpenseDialog(),
                      ).then((_) => StartIOAds.showInterstitial());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAddOption(
                    context,
                    'Income',
                    FontAwesomeIcons.arrowUp,
                    AppTheme.successColor,
                    () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => const AddIncomeDialog(),
                      ).then((_) => StartIOAds.showInterstitial());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddOption(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: FaIcon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
