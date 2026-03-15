import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../providers/health_provider.dart';
import '../models/health_record.dart';
import '../utils/app_theme.dart';
import '../widgets/add_health_record_dialog.dart';
import '../widgets/bmi_calculator_dialog.dart';
import '../widgets/add_vitals_dialog.dart';
import '../widgets/add_insurance_dialog.dart';
import '../services/startio_ads.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      bottomNavigationBar: const StartioBanner(),
      floatingActionButton: _buildFab(context),
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: true,
              pinned: true,
              elevation: 0,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Health & Wellness',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.healthColor.withValues(alpha: 0.05),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(FontAwesomeIcons.chartLine, size: 18),
                  ),
                  onPressed: () {
                    // Potential future feature: Detailed Analytics Screen
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color,
                  indicatorSize: TabBarIndicatorSize.label,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: AppTheme.healthColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.healthColor.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Vitals'),
                    Tab(text: 'Meds & Vaccines'),
                    Tab(text: 'Insurance'),
                    Tab(text: 'Records'),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildOverviewTab(healthProvider),
            _buildVitalsTab(healthProvider),
            _buildMedsAndVaccinesTab(healthProvider),
            _buildInsuranceTab(healthProvider),
            _buildRecordsTab(healthProvider),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        String label = 'Add Record';
        IconData icon = FontAwesomeIcons.plus;
        VoidCallback onPressed = () => _showAddRecordDialog(context);

        if (_tabController.index == 1) {
          // Vitals
          label = 'Log Vitals';
          icon = FontAwesomeIcons.heartPulse;
          onPressed = () => _showAddVitalsDialog(context);
        } else if (_tabController.index == 3) {
          // Insurance
          label = 'Add Policy';
          icon = FontAwesomeIcons.shieldHeart;
          onPressed = () => _showAddInsuranceDialog(context);
        }

        return FloatingActionButton.extended(
          onPressed: onPressed,
          label: Text(
            label,
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
          icon: FaIcon(icon, size: 16),
          backgroundColor: AppTheme.healthColor,
          elevation: 4,
        );
      },
    );
  }

  void _showAddRecordDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AddHealthRecordDialog(),
    );
    await StartIOAds.showInterstitial();
  }

  void _showBMICalculatorDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const BMICalculatorDialog(),
    );
    await StartIOAds.showInterstitial();
  }

  void _showAddVitalsDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AddVitalsDialog(),
    );
    await StartIOAds.showInterstitial();
  }

  void _showAddInsuranceDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => const AddInsuranceDialog(),
    );
    await StartIOAds.showInterstitial();
  }

  // ---------------------------------------------------------------------------
  // 1. OVERVIEW TAB
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(HealthProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final upcomingVisits = provider.getUpcomingVisits();
    final recentRecords = provider.getRecentRecords(limit: 5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(context),
          const SizedBox(height: 24),
          _buildQuickStats(provider),
          const SizedBox(height: 24),
          const Center(child: StartioMrec()),
          const SizedBox(height: 30),

          // Upcoming Appointments
          if (upcomingVisits.isNotEmpty) ...[
            Text(
              'Upcoming Visits',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: upcomingVisits.length,
                itemBuilder: (context, index) {
                  return _buildAppointmentCard(upcomingVisits[index]);
                },
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Recent Activity
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () =>
                    _tabController.animateTo(4), // Go to Records tab
                child: Text(
                  'View All',
                  style: GoogleFonts.inter(color: AppTheme.healthColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (recentRecords.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Center(
                child: Text(
                  "No health records found",
                  style: GoogleFonts.inter(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentRecords.map((record) => _buildModernRecordTile(record)),

          const SizedBox(height: 80), // Fab space
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2EB62C), const Color(0xFF57C84D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2EB62C).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.favorite,
              size: 150,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Summary Card
                // The original content of _buildHealthScoreCard is kept,
                // and the StartioMrec is already present in _buildOverviewTab.
                // The provided snippet seems to be for a different context or a different file.
                // Based on the instruction "Inject StartioMrec into the scrollable column after initial summary widgets",
                // and the existing StartioMrec in _buildOverviewTab, no change is needed here.
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Family Protected',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health Status',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Excellent',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Keep up the good work! All vaccinations are up to date.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(HealthProvider provider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            'Vitals',
            provider.getRecordsByType('Vitals').length.toString(),
            FontAwesomeIcons.heartPulse,
            const Color(0xFFFF4B4B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Vaccines',
            provider.healthRecords
                .where((r) => r.recordType.toLowerCase() == 'vaccination')
                .length
                .toString(),
            FontAwesomeIcons.syringe,
            const Color(0xFF4B89FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatItem(
            'Meds',
            provider.healthRecords
                .where((r) => r.recordType.toLowerCase() == 'medication')
                .length
                .toString(),
            FontAwesomeIcons.pills,
            const Color(0xFFFFB34B),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
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
      child: Column(
        children: [
          FaIcon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            count,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(HealthRecord record) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16, bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.healthColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.userDoctor,
                  size: 16,
                  color: AppTheme.healthColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.recordType,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      record.memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  record.nextVisit != null
                      ? DateFormat('MMM d, h:mm a').format(record.nextVisit!)
                      : 'No date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. VITALS TAB (With Charts)
  // ---------------------------------------------------------------------------
  Widget _buildVitalsTab(HealthProvider provider) {
    final vitalsRecords = provider.getRecordsByType('Vitals');

    // Sort by date for charts
    vitalsRecords.sort((a, b) => a.date.compareTo(b.date));

    // Basic Weight Data
    final weightSpots = vitalsRecords
        .where((r) => r.vitals?.weight != null)
        .map(
          (r) => FlSpot(
            r.date.millisecondsSinceEpoch.toDouble(),
            r.vitals!.weight!,
          ),
        )
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BMI Card
          _buildBMICalculatorCard(),
          const SizedBox(height: 24),

          if (weightSpots.isNotEmpty) ...[
            Text(
              'Weight Trend',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 250,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weightSpots,
                      isCurved: true,
                      color: AppTheme.healthColor,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.healthColor.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            'History',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (vitalsRecords.isEmpty)
            _buildEmptyState('No vitals logged yet.')
          else
            ...vitalsRecords.reversed.map(
              (record) => _buildModernRecordTile(record),
            ),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. MEDS & VACCINES TAB
  // ---------------------------------------------------------------------------
  Widget _buildMedsAndVaccinesTab(HealthProvider provider) {
    final meds = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'medication')
        .toList();
    final vaccines = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'vaccination')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Medications',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (meds.isEmpty) _buildEmptyState('No active medications'),
          ...meds.map((r) => _buildModernRecordTile(r)),

          const SizedBox(height: 24),
          Text(
            'Vaccinations',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (vaccines.isEmpty) _buildEmptyState('No vaccination records'),
          ...vaccines.map((r) => _buildModernRecordTile(r)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. INSURANCE TAB
  // ---------------------------------------------------------------------------
  Widget _buildInsuranceTab(HealthProvider provider) {
    final insurance = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'insurance')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          if (insurance.isEmpty)
            _buildEmptyState('No insurance policies added'),
          ...insurance.map((record) => _buildInsuranceCardDetails(record)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. ALL RECORDS TAB
  // ---------------------------------------------------------------------------
  Widget _buildRecordsTab(HealthProvider provider) {
    final records = provider.healthRecords;

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: records.length,
      itemBuilder: (context, index) {
        return _buildModernRecordTile(records[index]);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildModernRecordTile(HealthRecord record) {
    IconData icon;
    Color color;

    switch (record.recordType.toLowerCase()) {
      case 'vitals':
        icon = FontAwesomeIcons.heartPulse;
        color = const Color(0xFFFF4B4B);
        break;
      case 'medication':
        icon = FontAwesomeIcons.pills;
        color = const Color(0xFFFFB34B);
        break;
      case 'vaccination':
        icon = FontAwesomeIcons.syringe;
        color = const Color(0xFF4B89FF);
        break;
      case 'insurance':
        icon = FontAwesomeIcons.shieldHeart;
        color = const Color(0xFF2EB62C);
        break;
      default:
        icon = FontAwesomeIcons.fileMedical;
        color = Colors.purple;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: FaIcon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.recordType,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${record.memberName} • ${DateFormat('MMM d').format(record.date)}',
                  style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                ),
                if (record.description != null &&
                    record.description!.isNotEmpty)
                  Text(
                    record.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.grey),
            onPressed: () {
              // Open detailed view
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBMICalculatorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4B89FF).withValues(alpha: 0.1),
            const Color(0xFF4B89FF).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF4B89FF).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4B89FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const FaIcon(
              FontAwesomeIcons.calculator,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BMI Calculator',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Check your body mass index',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showBMICalculatorDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B89FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text('Check'),
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceCardDetails(HealthRecord record) {
    if (record.insurance == null) return const SizedBox.shrink();
    final info = record.insurance!;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF152A72), const Color(0xFF2E65F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E65F3).withValues(alpha: 0.4),
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
              Text(
                info.provider ?? 'Provider',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const Icon(Icons.shield, color: Colors.white54),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            info.policyNumber ?? 'XXXX-XXXX-XXXX',
            style: GoogleFonts.sourceCodePro(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MEMBER',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    record.memberName,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'VALID THRU',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    info.validUntil != null
                        ? DateFormat('MM/yy').format(info.validUntil!)
                        : 'N/A',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            FaIcon(
              FontAwesomeIcons.notesMedical,
              size: 40,
              color: Colors.grey.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(message, style: GoogleFonts.inter(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height + 16;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 16;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.only(bottom: 16),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
