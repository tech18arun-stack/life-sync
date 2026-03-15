import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';
// import '../utils/responsive.dart'; // TODO: Add responsive updates
import '../widgets/add_income_dialog.dart';
import '../services/startio_ads.dart';
import 'recent_income_screen.dart';

class IncomeScreen extends StatefulWidget {
  const IncomeScreen({super.key});

  @override
  State<IncomeScreen> createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<IncomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Theme Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: backgroundColor,
        bottomNavigationBar: const StartioBanner(),
        appBar: AppBar(
          title: Text(
            'Income & Balance',
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
          bottom: TabBar(
            controller: _tabController,
            labelColor: AppTheme.successColor,
            unselectedLabelColor: textSecondary,
            indicatorColor: AppTheme.successColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Monthly'),
              Tab(text: 'Yearly'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'add_income_fab',
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (context) => const AddIncomeDialog(),
            );
            await StartIOAds.showInterstitial();
          },
          backgroundColor: AppTheme.successColor,
          foregroundColor: Colors.white,
          icon: const FaIcon(FontAwesomeIcons.plus),
          label: const Text('Add Income'),
        ),
        body: Consumer<FinancialDataManager>(
          builder: (context, financialManager, child) {
            return TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(
                  financialManager,
                  isDark,
                  cardColor,
                  textPrimary,
                  textSecondary,
                ),
                _buildMonthlyTab(
                  financialManager,
                  isDark,
                  cardColor,
                  textPrimary,
                  textSecondary,
                ),
                _buildYearlyTab(
                  financialManager,
                  isDark,
                  cardColor,
                  textPrimary,
                  textSecondary,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    FinancialDataManager manager,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final totalIncome = manager.getTotalIncome();
    final totalExpenses = manager.getTotalExpenses();
    final availableBalance = manager.getAvailableBalance();
    final monthlyIncome = manager.getMonthlyIncome();
    final monthlyExpenses = manager.getMonthlyExpenses();
    final monthlyAvailable = manager.getMonthlyAvailableBalance();

    return CustomScrollView(
      slivers: [
        // Main Balance Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.successColor,
                    const Color(0xFF1B5E20), // Darker green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    top: -10,
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white.withOpacity(0.1),
                      size: 80,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Available Balance',
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Overall',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${NumberFormat('#,##,##0.00', 'en_IN').format(availableBalance)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBalanceDetail(
                              'Income',
                              totalIncome,
                              FontAwesomeIcons.arrowTrendUp,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildBalanceDetail(
                              'Spent',
                              totalExpenses,
                              FontAwesomeIcons.arrowTrendDown,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Monthly Summary Card
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor.withOpacity(0.8),
                    AppTheme.accentColor.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -10,
                    bottom: -10,
                    child: Icon(
                      Icons.calendar_month,
                      color: Colors.white.withOpacity(0.1),
                      size: 60,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'This Month',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(DateTime.now()),
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '₹${NumberFormat('#,##,##0.00', 'en_IN').format(monthlyAvailable)}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Net savings this month',
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          _buildMiniStat('Income', monthlyIncome),
                          const SizedBox(width: 24),
                          _buildMiniStat('Expenses', monthlyExpenses),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Statistics Grid
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Overview',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Savings Rate',
                        '${manager.getSavingsPercentage().toStringAsFixed(1)}%',
                        FontAwesomeIcons.chartPie,
                        AppTheme.accentColor,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Income Sources',
                        '${manager.getIncomeBySource().length}',
                        FontAwesomeIcons.briefcase,
                        AppTheme.primaryColor,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total Transactions',
                        '${manager.incomes.length}',
                        FontAwesomeIcons.receipt,
                        AppTheme.warningColor,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Health Score',
                        manager.getFinancialHealthScore().toStringAsFixed(0),
                        FontAwesomeIcons.heartPulse,
                        AppTheme.healthColor,
                        cardColor,
                        textPrimary,
                        textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Recent Income List Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Income',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RecentIncomeScreen(),
                      ),
                    );
                  },
                  icon: const FaIcon(FontAwesomeIcons.arrowRight, size: 14),
                  label: const Text('View All'),
                ),
              ],
            ),
          ),
        ),

        _buildIncomeList(
          context,
          manager,
          cardColor,
          textPrimary,
          textSecondary,
          limit: 5,
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  Widget _buildMonthlyTab(
    FinancialDataManager manager,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final now = DateTime.now();
    final months = List.generate(
      12,
      (index) => DateTime(now.year, now.month - index, 1),
    );

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: months.length,
      itemBuilder: (context, index) {
        final month = months[index];
        final monthIncome = manager.getIncomeForMonth(month);
        final monthExpenses = manager.getExpensesForMonth(month);
        final monthAvailable = monthIncome - monthExpenses;

        return _buildMonthCard(
          context,
          month,
          monthIncome,
          monthExpenses,
          monthAvailable,
          cardColor,
          textPrimary,
          textSecondary,
        );
      },
    );
  }

  Widget _buildYearlyTab(
    FinancialDataManager manager,
    bool isDark,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final now = DateTime.now();
    final years = List.generate(5, (index) => now.year - index);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: years.length,
      itemBuilder: (context, index) {
        final year = years[index];
        final yearIncome = manager.getIncomeForYear(year);
        final yearExpenses = manager.getExpensesForYear(year);
        final yearAvailable = yearIncome - yearExpenses;

        return _buildYearCard(
          context,
          year,
          yearIncome,
          yearExpenses,
          yearAvailable,
          cardColor,
          textPrimary,
          textSecondary,
        );
      },
    );
  }

  Widget _buildMonthCard(
    BuildContext context,
    DateTime month,
    double income,
    double expenses,
    double available,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isCurrentMonth =
        month.year == DateTime.now().year &&
        month.month == DateTime.now().month;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrentMonth
            ? AppTheme.primaryColor.withValues(alpha: 0.1)
            : cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentMonth
              ? AppTheme.primaryColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: isCurrentMonth ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(month),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  color: isCurrentMonth ? AppTheme.primaryColor : textPrimary,
                  fontSize: 16,
                ),
              ),
              if (isCurrentMonth)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Current',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMonthStat(
            'Available',
            available,
            FontAwesomeIcons.wallet,
            available >= 0 ? AppTheme.successColor : AppTheme.errorColor,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMonthStat(
                  'Income',
                  income,
                  FontAwesomeIcons.arrowTrendUp,
                  AppTheme.successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMonthStat(
                  'Expenses',
                  expenses,
                  FontAwesomeIcons.arrowTrendDown,
                  AppTheme.errorColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildYearCard(
    BuildContext context,
    int year,
    double income,
    double expenses,
    double available,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    final isCurrentYear = year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color:
            cardColor, // Always use card color, handle active state with border
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentYear
              ? AppTheme.accentColor.withValues(alpha: 0.4)
              : Colors.transparent,
          width: isCurrentYear ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                year.toString(),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: isCurrentYear ? AppTheme.accentColor : textPrimary,
                ),
              ),
              if (isCurrentYear)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Current Year',
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
          Text(
            '₹${available.toStringAsFixed(2)}',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: available >= 0
                  ? AppTheme.successColor
                  : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: 4),
          Text('Net Balance', style: GoogleFonts.inter(color: textSecondary)),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.arrowTrendUp,
                          color: AppTheme.successColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Income',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${income.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        FaIcon(
                          FontAwesomeIcons.arrowTrendDown,
                          color: AppTheme.errorColor,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Expenses',
                          style: GoogleFonts.inter(
                            color: textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${expenses.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDetail(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FaIcon(icon, color: Colors.white.withOpacity(0.7), size: 12),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${NumberFormat('#,##,###', 'en_IN').format(amount)}',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(String label, double amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white.withOpacity(0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '₹${NumberFormat('#,##,###', 'en_IN').format(amount)}',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, color: color, size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
              ),
              Text(
                '₹${amount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  SliverList _buildIncomeList(
    BuildContext context,
    FinancialDataManager manager,
    Color cardColor,
    Color textPrimary,
    Color textSecondary, {
    int? limit,
  }) {
    final incomes = limit != null
        ? manager.incomes.take(limit).toList()
        : manager.incomes;

    if (incomes.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  FaIcon(
                    FontAwesomeIcons.moneyBillTrendUp,
                    size: 64,
                    color: textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No income records yet',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your first income to get started',
                    style: GoogleFonts.inter(color: textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final income = incomes.elementAt(index);
        final color = AppTheme.getCategoryColor(income.source);

        return Dismissible(
          key: Key(income.id ?? ''),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: AppTheme.errorColor,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.centerRight,
            child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
          ),
          onDismissed: (direction) {
            manager.deleteIncome(income.id ?? '');
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Income deleted')));
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddIncomeDialog(income: income),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.moneyBill,
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
                              income.title,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  income.source,
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  ' • ',
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  DateFormat('MMM d, yyyy').format(income.date),
                                  style: GoogleFonts.inter(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '+₹${income.amount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          color: AppTheme.successColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }, childCount: incomes.length),
    );
  }
}
