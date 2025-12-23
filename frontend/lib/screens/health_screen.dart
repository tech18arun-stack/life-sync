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
    _tabController = TabController(length: 7, vsync: this);
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
              icon: FaIcon(FontAwesomeIcons.heartPulse, size: 20),
              text: 'Vitals',
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
              icon: FaIcon(FontAwesomeIcons.triangleExclamation, size: 20),
              text: 'Allergies',
            ),
            Tab(
              icon: FaIcon(FontAwesomeIcons.shieldHeart, size: 20),
              text: 'Insurance',
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
          _buildVitalsTab(healthProvider),
          _buildVaccinationsTab(healthProvider),
          _buildMedicationsTab(healthProvider),
          _buildAllergiesTab(healthProvider),
          _buildInsuranceTab(healthProvider),
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

  // Vitals Tab - BMI, Blood Pressure, Heart Rate, etc.
  Widget _buildVitalsTab(HealthProvider provider) {
    final vitalsRecords = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'vitals')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // BMI Calculator Card
          _buildBMICalculatorCard(),
          const SizedBox(height: 24),

          // Blood Pressure Tracker Card
          _buildBloodPressureTrackerCard(),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Vitals History',
            FontAwesomeIcons.heartPulse,
            color: AppTheme.healthColor,
          ),
          const SizedBox(height: 12),

          if (vitalsRecords.isEmpty)
            _buildEmptyState(
              context,
              'No vitals recorded',
              'Track your vital signs like BP, heart rate, weight, and more',
              FontAwesomeIcons.heartPulse,
            )
          else
            ...vitalsRecords.map(
              (record) => _buildVitalsCard(context, record, provider),
            ),
          const SizedBox(height: 100),
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
            AppTheme.primaryColor.withOpacity(0.2),
            AppTheme.accentColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.scaleUnbalanced,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'BMI Calculator',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showBMICalculatorDialog(context),
                icon: const FaIcon(FontAwesomeIcons.calculator, size: 14),
                label: const Text('Calculate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track your Body Mass Index to monitor your health',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildBMICategoryChip('< 18.5', 'Underweight', Colors.blue),
              const SizedBox(width: 8),
              _buildBMICategoryChip('18.5-24.9', 'Normal', Colors.green),
              const SizedBox(width: 8),
              _buildBMICategoryChip('25-29.9', 'Overweight', Colors.orange),
              const SizedBox(width: 8),
              _buildBMICategoryChip('≥ 30', 'Obese', Colors.red),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBMICategoryChip(String range, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              range,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(label, style: TextStyle(fontSize: 8, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBloodPressureTrackerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.errorColor.withOpacity(0.15),
            AppTheme.errorColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.errorColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.heartPulse,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Blood Pressure & Vitals',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddVitalsDialog(context),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Log'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track blood pressure, heart rate, blood sugar & more',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildVitalIndicator('🩸', 'Blood Pressure', 'mmHg'),
              _buildVitalIndicator('❤️', 'Heart Rate', 'bpm'),
              _buildVitalIndicator('🍬', 'Blood Sugar', 'mg/dL'),
              _buildVitalIndicator('🌡️', 'Temperature', '°F'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVitalIndicator(String emoji, String label, String unit) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        Text(
          unit,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildVitalsCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    final vitals = record.vitals;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.healthColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                record.memberName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                DateFormat('MMM d, yyyy').format(record.date),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (vitals != null) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                if (vitals.bloodPressureSystolic != null &&
                    vitals.bloodPressureDiastolic != null)
                  _buildVitalChip(
                    '🩸',
                    '${vitals.bloodPressureSystolic!.toInt()}/${vitals.bloodPressureDiastolic!.toInt()} mmHg',
                  ),
                if (vitals.heartRate != null)
                  _buildVitalChip('❤️', '${vitals.heartRate!.toInt()} bpm'),
                if (vitals.bloodSugar != null)
                  _buildVitalChip('🍬', '${vitals.bloodSugar!.toInt()} mg/dL'),
                if (vitals.weight != null)
                  _buildVitalChip(
                    '⚖️',
                    '${vitals.weight!.toStringAsFixed(1)} kg',
                  ),
                if (vitals.bmi != null)
                  _buildVitalChip(
                    '📊',
                    'BMI: ${vitals.bmi!.toStringAsFixed(1)}',
                  ),
                if (vitals.oxygenLevel != null)
                  _buildVitalChip(
                    '💨',
                    'SpO2: ${vitals.oxygenLevel!.toInt()}%',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVitalChip(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.healthColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // Allergies Tab
  Widget _buildAllergiesTab(HealthProvider provider) {
    final allergyRecords = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'allergy')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Allergy Alert Card
          _buildAllergyAlertCard(),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Family Allergies',
            FontAwesomeIcons.triangleExclamation,
            color: AppTheme.warningColor,
          ),
          const SizedBox(height: 12),

          if (allergyRecords.isEmpty)
            _buildEmptyState(
              context,
              'No allergies recorded',
              'Keep track of family allergies for safety',
              FontAwesomeIcons.triangleExclamation,
            )
          else
            ...allergyRecords.map(
              (record) => _buildAllergyCard(context, record, provider),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildAllergyAlertCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.warningColor.withOpacity(0.2),
            AppTheme.errorColor.withOpacity(0.1),
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
                  FontAwesomeIcons.shieldVirus,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Allergy Tracker',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddAllergyDialog(context),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Track allergies for all family members in one place',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const FaIcon(
                FontAwesomeIcons.circleInfo,
                size: 14,
                color: AppTheme.warningColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Include food, drug, environmental & seasonal allergies',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllergyCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    final allergy = record.allergy;
    final severityColor = _getAllergySeverityColor(allergy?.severity ?? 'Mild');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: FaIcon(
              FontAwesomeIcons.triangleExclamation,
              color: severityColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      allergy?.allergen ?? 'Unknown Allergen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: severityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        allergy?.severity ?? 'Mild',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: severityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Member: ${record.memberName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (allergy?.reactions != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Reactions: ${allergy!.reactions}',
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getAllergySeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
        return AppTheme.errorColor;
      case 'moderate':
        return AppTheme.warningColor;
      default:
        return AppTheme.successColor;
    }
  }

  // Insurance Tab
  Widget _buildInsuranceTab(HealthProvider provider) {
    final insuranceRecords = provider.healthRecords
        .where((r) => r.recordType.toLowerCase() == 'insurance')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insurance Overview Card
          _buildInsuranceOverviewCard(),
          const SizedBox(height: 24),

          _buildSectionHeader(
            context,
            'Health Insurance Policies',
            FontAwesomeIcons.shieldHeart,
            color: AppTheme.infoColor,
          ),
          const SizedBox(height: 12),

          if (insuranceRecords.isEmpty)
            _buildEmptyState(
              context,
              'No insurance policies',
              'Add your health insurance details for quick access',
              FontAwesomeIcons.shieldHeart,
            )
          else
            ...insuranceRecords.map(
              (record) => _buildInsuranceCard(context, record, provider),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildInsuranceOverviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.infoColor.withOpacity(0.2),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.infoColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(
                  FontAwesomeIcons.fileShield,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Insurance Manager',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showAddInsuranceDialog(context),
                icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                label: const Text('Add'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.infoColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Keep all your health insurance details in one place',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInsuranceFeature(FontAwesomeIcons.idCard, 'Policy Details'),
              const SizedBox(width: 16),
              _buildInsuranceFeature(
                FontAwesomeIcons.calendarCheck,
                'Expiry Alerts',
              ),
              const SizedBox(width: 16),
              _buildInsuranceFeature(
                FontAwesomeIcons.moneyBill,
                'Coverage Info',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsuranceFeature(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: AppTheme.infoColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            FaIcon(icon, size: 16, color: AppTheme.infoColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsuranceCard(
    BuildContext context,
    HealthRecord record,
    HealthProvider provider,
  ) {
    final insurance = record.insurance;
    final isExpired = insurance?.isExpired ?? false;
    final daysLeft = insurance?.daysUntilExpiry ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpired
              ? AppTheme.errorColor.withOpacity(0.3)
              : (daysLeft < 30
                    ? AppTheme.warningColor.withOpacity(0.3)
                    : AppTheme.infoColor.withOpacity(0.2)),
        ),
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
                  color: AppTheme.infoColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: FaIcon(
                  FontAwesomeIcons.shieldHeart,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      insurance?.provider ?? 'Insurance Provider',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Policy: ${insurance?.policyNumber ?? 'N/A'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isExpired
                      ? AppTheme.errorColor.withOpacity(0.2)
                      : (daysLeft < 30
                            ? AppTheme.warningColor.withOpacity(0.2)
                            : AppTheme.successColor.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isExpired
                      ? 'Expired'
                      : (daysLeft < 30 ? '$daysLeft days left' : 'Active'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isExpired
                        ? AppTheme.errorColor
                        : (daysLeft < 30
                              ? AppTheme.warningColor
                              : AppTheme.successColor),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Member', style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    record.memberName,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Coverage',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    insurance?.coverageAmount != null
                        ? '₹${insurance!.coverageAmount!.toStringAsFixed(0)}'
                        : 'N/A',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (insurance?.validUntil != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.calendarDays,
                  size: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 6),
                Text(
                  'Valid until: ${DateFormat('MMM d, yyyy').format(insurance!.validUntil!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
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

  // BMI Calculator Dialog
  void _showBMICalculatorDialog(BuildContext context) {
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    double? calculatedBMI;
    String bmiCategory = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.scaleUnbalanced,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('BMI Calculator'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (kg)',
                    prefixIcon: Icon(Icons.monitor_weight),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (weightController.text.isNotEmpty &&
                        heightController.text.isNotEmpty) {
                      final weight =
                          double.tryParse(weightController.text) ?? 0;
                      final height =
                          double.tryParse(heightController.text) ?? 0;
                      if (weight > 0 && height > 0) {
                        final heightM = height / 100;
                        setState(() {
                          calculatedBMI = weight / (heightM * heightM);
                          bmiCategory = _getBMICategoryString(calculatedBMI!);
                        });
                      }
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Height (cm)',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    if (weightController.text.isNotEmpty &&
                        heightController.text.isNotEmpty) {
                      final weight =
                          double.tryParse(weightController.text) ?? 0;
                      final height =
                          double.tryParse(heightController.text) ?? 0;
                      if (weight > 0 && height > 0) {
                        final heightM = height / 100;
                        setState(() {
                          calculatedBMI = weight / (heightM * heightM);
                          bmiCategory = _getBMICategoryString(calculatedBMI!);
                        });
                      }
                    }
                  },
                ),
                if (calculatedBMI != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _getBMIColor(bmiCategory).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _getBMIColor(bmiCategory)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Your BMI',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          calculatedBMI!.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: _getBMIColor(bmiCategory),
                          ),
                        ),
                        Text(
                          bmiCategory,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getBMIColor(bmiCategory),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  String _getBMICategoryString(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color _getBMIColor(String category) {
    switch (category) {
      case 'Underweight':
        return Colors.blue;
      case 'Normal':
        return Colors.green;
      case 'Overweight':
        return Colors.orange;
      case 'Obese':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Add Vitals Dialog
  void _showAddVitalsDialog(BuildContext context) {
    final memberController = TextEditingController();
    final systolicController = TextEditingController();
    final diastolicController = TextEditingController();
    final heartRateController = TextEditingController();
    final bloodSugarController = TextEditingController();
    final weightController = TextEditingController();
    final heightController = TextEditingController();
    final oxygenController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Row(
          children: [
            FaIcon(
              FontAwesomeIcons.heartPulse,
              color: AppTheme.errorColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            const Text('Log Vitals'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: memberController,
                decoration: const InputDecoration(
                  labelText: 'Family Member Name',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: systolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Systolic (mmHg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: diastolicController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Diastolic (mmHg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: heartRateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Heart Rate (bpm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: bloodSugarController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Blood Sugar',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight (kg)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height (cm)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: oxygenController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Oxygen Level (%)',
                  prefixIcon: Icon(Icons.air),
                  border: OutlineInputBorder(),
                ),
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
              if (memberController.text.isNotEmpty) {
                final weight = double.tryParse(weightController.text);
                final height = double.tryParse(heightController.text);
                double? bmi;
                if (weight != null && height != null && height > 0) {
                  final heightM = height / 100;
                  bmi = weight / (heightM * heightM);
                }

                final record = HealthRecord(
                  memberName: memberController.text,
                  recordType: 'Vitals',
                  date: DateTime.now(),
                  vitals: Vitals(
                    bloodPressureSystolic: double.tryParse(
                      systolicController.text,
                    ),
                    bloodPressureDiastolic: double.tryParse(
                      diastolicController.text,
                    ),
                    heartRate: double.tryParse(heartRateController.text),
                    bloodSugar: double.tryParse(bloodSugarController.text),
                    weight: weight,
                    height: height,
                    bmi: bmi,
                    oxygenLevel: double.tryParse(oxygenController.text),
                  ),
                );

                Provider.of<HealthProvider>(
                  context,
                  listen: false,
                ).addHealthRecord(record);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vitals logged successfully!')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Add Allergy Dialog
  void _showAddAllergyDialog(BuildContext context) {
    final memberController = TextEditingController();
    final allergenController = TextEditingController();
    final reactionsController = TextEditingController();
    final treatmentController = TextEditingController();
    String severity = 'Mild';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.triangleExclamation,
                color: AppTheme.warningColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Add Allergy'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: memberController,
                  decoration: const InputDecoration(
                    labelText: 'Family Member Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: allergenController,
                  decoration: const InputDecoration(
                    labelText: 'Allergen (e.g., Peanuts, Dust)',
                    prefixIcon: Icon(Icons.warning_amber),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: severity,
                  decoration: const InputDecoration(
                    labelText: 'Severity',
                    prefixIcon: Icon(Icons.speed),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Mild', 'Moderate', 'Severe'].map((s) {
                    return DropdownMenuItem(value: s, child: Text(s));
                  }).toList(),
                  onChanged: (value) => setState(() => severity = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reactionsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Reactions',
                    hintText: 'e.g., Hives, swelling, difficulty breathing',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: treatmentController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Treatment',
                    hintText: 'e.g., Antihistamines, EpiPen',
                    border: OutlineInputBorder(),
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.warningColor,
              ),
              onPressed: () {
                if (memberController.text.isNotEmpty &&
                    allergenController.text.isNotEmpty) {
                  final record = HealthRecord(
                    memberName: memberController.text,
                    recordType: 'Allergy',
                    date: DateTime.now(),
                    allergy: AllergyInfo(
                      allergen: allergenController.text,
                      severity: severity,
                      reactions: reactionsController.text.isEmpty
                          ? null
                          : reactionsController.text,
                      treatment: treatmentController.text.isEmpty
                          ? null
                          : treatmentController.text,
                    ),
                  );

                  Provider.of<HealthProvider>(
                    context,
                    listen: false,
                  ).addHealthRecord(record);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Allergy added successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // Add Insurance Dialog
  void _showAddInsuranceDialog(BuildContext context) {
    final memberController = TextEditingController();
    final providerController = TextEditingController();
    final policyController = TextEditingController();
    final coverageController = TextEditingController();
    final policyTypeController = TextEditingController();
    DateTime validUntil = DateTime.now().add(const Duration(days: 365));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: Row(
            children: [
              FaIcon(
                FontAwesomeIcons.shieldHeart,
                color: AppTheme.infoColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              const Text('Add Insurance'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: memberController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Holder Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: providerController,
                  decoration: const InputDecoration(
                    labelText: 'Insurance Provider',
                    prefixIcon: Icon(Icons.business),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: policyController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Number',
                    prefixIcon: Icon(Icons.numbers),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: policyTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Policy Type',
                    hintText: 'e.g., Family Floater, Individual',
                    prefixIcon: Icon(Icons.category),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: coverageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Coverage Amount (₹)',
                    prefixIcon: Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Valid Until'),
                  subtitle: Text(DateFormat('MMM d, yyyy').format(validUntil)),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: validUntil,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 3650),
                        ),
                      );
                      if (picked != null) {
                        setState(() => validUntil = picked);
                      }
                    },
                  ),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.infoColor,
              ),
              onPressed: () {
                if (memberController.text.isNotEmpty &&
                    providerController.text.isNotEmpty) {
                  final record = HealthRecord(
                    memberName: memberController.text,
                    recordType: 'Insurance',
                    date: DateTime.now(),
                    insurance: InsuranceInfo(
                      provider: providerController.text,
                      policyNumber: policyController.text.isEmpty
                          ? null
                          : policyController.text,
                      policyType: policyTypeController.text.isEmpty
                          ? null
                          : policyTypeController.text,
                      coverageAmount: double.tryParse(coverageController.text),
                      validUntil: validUntil,
                    ),
                  );

                  Provider.of<HealthProvider>(
                    context,
                    listen: false,
                  ).addHealthRecord(record);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Insurance added successfully!'),
                    ),
                  );
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
