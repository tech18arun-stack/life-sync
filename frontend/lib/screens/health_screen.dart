import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/health_provider.dart';
import '../models/health_record.dart';
import '../utils/app_theme.dart';
import '../widgets/add_health_record_dialog.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    final healthProvider = Provider.of<HealthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health & Wellness'),
        actions: [
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.chartLine),
            tooltip: 'Health Insights',
            onPressed: () => _showHealthInsights(context, healthProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(
              icon: FaIcon(FontAwesomeIcons.houseChimneyMedical, size: 20),
              text: 'Overview',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.syringe, size: 20),
              text: 'Vaccinations',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.pills, size: 20),
              text: 'Medications',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.fileWaveform, size: 20),
              text: 'Records',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(healthProvider),
          _buildVaccinationsTab(healthProvider),
          _buildMedicationsTab(healthProvider),
          _buildRecordsTab(healthProvider),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_health_record_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddHealthRecordDialog(),
          );
        },
        icon: const FaIcon(FontAwesomeIcons.plus),
        label: const Text('Add Record'),
      ),
    );
  }

  // Overview Tab
  Widget _buildOverviewTab(HealthProvider provider) {
    final upcomingVisits = provider.getUpcomingVisits();
    final recentRecords = provider.getRecentRecords().take(5).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Health Stats Grid
          _buildHealthStatsGrid(provider),
          const SizedBox(height: 24),

          // Upcoming Appointments
          if (upcomingVisits.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Upcoming Appointments',
              FontAwesomeIcons.calendarDays,
              color: AppTheme.warningColor,
            ),
            const SizedBox(height: 12),
            ...upcomingVisits
                .take(3)
                .map(
                  (record) => _buildAppointmentCard(context, record, provider),
                ),
            const SizedBox(height: 24),
          ],

          // Quick Health Tips
          _buildHealthTipsCard(),
          const SizedBox(height: 24),

          // Recent Records
          if (recentRecords.isNotEmpty) ...[
            _buildSectionHeader(
              context,
              'Recent Activity',
              FontAwesomeIcons.clockRotateLeft,
              color: AppTheme.infoColor,
            ),
            const SizedBox(height: 12),
            ...recentRecords.map(
              (record) => _buildCompactRecordCard(context, record, provider),
            ),
          ],

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Vaccinations Tab
  Widget _buildVaccinationsTab(HealthProvider provider) {
    final vaccinations = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'vaccination')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildVaccinationScheduleCard(),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Vaccination History',
            FontAwesomeIcons.clockRotateLeft,
            color: AppTheme.successColor,
          ),
          const SizedBox(height: 12),

          if (vaccinations.isEmpty)
            _buildEmptyState(
              context,
              'No vaccination records',
              'Add vaccination records to track immunization history',
              FontAwesomeIcons.syringe,
            )
          else
            ...vaccinations.map(
              (record) => _buildHealthRecordCard(context, record, provider),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Medications Tab
  Widget _buildMedicationsTab(HealthProvider provider) {
    final medications = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'medication')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMedicationReminderCard(),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Current Medications',
            FontAwesomeIcons.pills,
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 12),

          if (medications.isEmpty)
            _buildEmptyState(
              context,
              'No medications',
              'Add medication records to track prescriptions and dosages',
              FontAwesomeIcons.pills,
            )
          else
            ...medications.map(
              (record) => _buildHealthRecordCard(context, record, provider),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // Records Tab
  Widget _buildRecordsTab(HealthProvider provider) {
    final allRecords = provider.healthRecords;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            context,
            'All Health Records',
            FontAwesomeIcons.fileWaveform,
            color: AppTheme.healthColor,
          ),
          const SizedBox(height: 12),

          if (allRecords.isEmpty)
            _buildEmptyState(
              context,
              'No health records yet',
              'Start tracking your family\'s health by adding records',
              FontAwesomeIcons.heartPulse,
            )
          else
            ...allRecords.map(
              (record) => _buildHealthRecordCard(context, record, provider),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHealthStatsGrid(HealthProvider provider) {
    final upcomingCount = provider.getUpcomingVisits().length;
    final vaccinationCount = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'vaccination')
        .length;
    final medicationCount = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'medication')
        .length;

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          context,
          'Total Records',
          '${provider.healthRecords.length}',
          FontAwesomeIcons.fileWaveform,
          AppTheme.healthColor,
        ),
        _buildStatCard(
          context,
          'Upcoming Visits',
          '$upcomingCount',
          FontAwesomeIcons.calendarCheck,
          AppTheme.warningColor,
        ),
        _buildStatCard(
          context,
          'Vaccinations',
          '$vaccinationCount',
          FontAwesomeIcons.syringe,
          AppTheme.successColor,
        ),
        _buildStatCard(
          context,
          'Medications',
          '$medicationCount',
          FontAwesomeIcons.pills,
          AppTheme.infoColor,
        ),
      ],
    );
  }

  Widget _buildHealthTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.2),
            AppTheme.infoColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.lightbulb,
                color: AppTheme.successColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Daily Health Tips',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHealthTipItem('💧', 'Drink 8 glasses of water daily'),
          const SizedBox(height: 8),
          _buildHealthTipItem('🏃', 'Get 30 minutes of exercise'),
          const SizedBox(height: 8),
          _buildHealthTipItem('😴', 'Sleep 7-8 hours per night'),
          const SizedBox(height: 8),
          _buildHealthTipItem('🥗', 'Eat balanced, nutritious meals'),
        ],
      ),
    );
  }

  Widget _buildHealthTipItem(String emoji, String tip) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(tip, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildVaccinationScheduleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successColor.withOpacity(0.2),
            AppTheme.successColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.successColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.calendarCheck,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Vaccination Schedule',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep your family protected with timely vaccinations',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 14,
                color: AppTheme.successColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Track COVID-19, Flu, and routine immunizations',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationReminderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withOpacity(0.2),
            AppTheme.warningColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.warningColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.bell,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Medication Reminders',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Never miss a dose with smart reminders',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleCheck,
                size: 14,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Set up daily, weekly, or custom schedules',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    Color? color,
  }) {
    final headerColor = color ?? AppTheme.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: headerColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FaIcon(icon, size: 16, color: headerColor),
        ),
        const SizedBox(width: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FaIcon(icon, color: color, size: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.healthColor.withOpacity(0.2),
            AppTheme.healthColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.healthColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.healthColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  DateFormat('MMM').format(record.nextVisit!).toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.backgroundColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${record.nextVisit!.day}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.backgroundColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.recordType,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'For: ${record.memberName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (record.doctorName != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FaIcon(
                        FontAwesomeIcons.userDoctor,
                        size: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          record.doctorName!,
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactRecordCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    final color = _getRecordTypeColor(record.recordType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(
              _getRecordTypeIcon(record.recordType),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.recordType,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  '${record.memberName} • ${DateFormat('MMM d').format(record.date)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRecordCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    final color = _getRecordTypeColor(record.recordType);

    return Dismissible(
      key: Key(record.id ?? ''),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppTheme.errorColor,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        child: const FaIcon(FontAwesomeIcons.trash, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Record?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.errorColor,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        provider.deleteHealthRecord(record.id ?? '');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Record deleted')));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FaIcon(
                    _getRecordTypeIcon(record.recordType),
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
                        record.recordType,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        record.memberName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      DateFormat('MMM d').format(record.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      DateFormat('yyyy').format(record.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            if (record.description != null &&
                record.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  record.description!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
            if (record.doctorName != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.userDoctor,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    record.doctorName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
            if (record.nextVisit != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.warningColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FaIcon(
                      FontAwesomeIcons.calendarDays,
                      size: 12,
                      color: AppTheme.warningColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next visit: ${DateFormat('MMM d, yyyy').format(record.nextVisit!)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRecordTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'checkup':
        return AppTheme.infoColor;
      case 'vaccination':
        return AppTheme.successColor;
      case 'medication':
        return AppTheme.warningColor;
      case 'lab test':
        return Colors.purple;
      case 'surgery':
        return Colors.red;
      default:
        return AppTheme.healthColor;
    }
  }

  IconData _getRecordTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checkup':
        return FontAwesomeIcons.stethoscope;
      case 'vaccination':
        return FontAwesomeIcons.syringe;
      case 'medication':
        return FontAwesomeIcons.pills;
      case 'lab test':
        return FontAwesomeIcons.flask;
      case 'surgery':
        return FontAwesomeIcons.userDoctor;
      default:
        return FontAwesomeIcons.heartPulse;
    }
  }

  Widget _buildEmptyState(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          FaIcon(
            icon,
            size: 64,
            color: Theme.of(
              context,
            ).textTheme.bodySmall?.color?.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showHealthInsights(BuildContext context, HealthProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const FaIcon(
                    FontAwesomeIcons.chartLine,
                    color: AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Health Insights',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInsightCard(
                'Health Coverage',
                'Your family has ${provider.healthRecords.length} health records tracked',
                FontAwesomeIcons.shieldHeart,
                AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Vaccination Status',
                'Keep your family protected with regular immunizations',
                FontAwesomeIcons.syringe,
                AppTheme.infoColor,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Regular Checkups',
                'Schedule annual checkups for preventive care',
                FontAwesomeIcons.calendarCheck,
                AppTheme.warningColor,
              ),
              const SizedBox(height: 16),
              _buildInsightCard(
                'Medication Adherence',
                'Take medications as prescribed for best results',
                FontAwesomeIcons.pills,
                AppTheme.healthColor,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
