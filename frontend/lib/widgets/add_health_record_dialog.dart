import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/health_record.dart';
import '../providers/health_provider.dart';
import '../utils/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddHealthRecordDialog extends StatefulWidget {
  const AddHealthRecordDialog({super.key});

  @override
  State<AddHealthRecordDialog> createState() => _AddHealthRecordDialogState();
}

class _AddHealthRecordDialogState extends State<AddHealthRecordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _memberController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _doctorController = TextEditingController();
  final _medicationController = TextEditingController();

  String _selectedType = 'Checkup';
  DateTime _selectedDate = DateTime.now();
  DateTime? _nextVisit;
  bool _hasNextVisit = false;

  final List<String> _recordTypes = [
    'Checkup',
    'Vaccination',
    'Medication',
    'Lab Test',
    'Surgery',
    'Emergency',
    'Dental',
    'Eye Care',
  ];

  @override
  void dispose() {
    _memberController.dispose();
    _descriptionController.dispose();
    _doctorController.dispose();
    _medicationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.healthColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.heartPulse,
                          color: AppTheme.healthColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Add Health Record',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _memberController,
                decoration: const InputDecoration(
                  labelText: 'Family Member',
                  hintText: 'e.g., John Doe',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter family member name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Record Type',
                  prefixIcon: Icon(Icons.medical_services),
                ),
                items: _recordTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        FaIcon(
                          _getTypeIcon(type),
                          size: 16,
                          color: AppTheme.healthColor,
                        ),
                        const SizedBox(width: 12),
                        Text(type),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
                dropdownColor: Theme.of(context).cardColor,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Details about the visit/treatment',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _doctorController,
                decoration: const InputDecoration(
                  labelText: 'Doctor Name (Optional)',
                  hintText: 'Dr. Name',
                  prefixIcon: Icon(Icons.local_hospital),
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicationController,
                decoration: const InputDecoration(
                  labelText: 'Medication (Optional)',
                  hintText: 'Prescribed medicines',
                  prefixIcon: Icon(Icons.medication),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _selectedDate = date;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Record Date',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _hasNextVisit,
                onChanged: (value) {
                  setState(() {
                    _hasNextVisit = value ?? false;
                    if (!_hasNextVisit) {
                      _nextVisit = null;
                    }
                  });
                },
                title: const Text('Schedule Next Visit'),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.primaryColor,
              ),

              if (_hasNextVisit) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() {
                        _nextVisit = date;
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.healthColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.healthColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const FaIcon(
                          FontAwesomeIcons.calendarCheck,
                          size: 16,
                          color: AppTheme.healthColor,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Next Visit Date',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _nextVisit != null
                                  ? '${_nextVisit!.day}/${_nextVisit!.month}/${_nextVisit!.year}'
                                  : 'Tap to select',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: _nextVisit != null
                                        ? Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.color
                                        : Theme.of(
                                            context,
                                          ).textTheme.bodySmall?.color,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveHealthRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.healthColor,
                    foregroundColor: AppTheme.backgroundColor,
                  ),
                  child: const Text('Add Health Record'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'checkup':
        return FontAwesomeIcons.stethoscope;
      case 'vaccination':
        return FontAwesomeIcons.syringe;
      case 'medication':
        return FontAwesomeIcons.pills;
      case 'lab test':
        return FontAwesomeIcons.vial;
      case 'surgery':
        return FontAwesomeIcons.scissors;
      case 'emergency':
        return FontAwesomeIcons.truckMedical;
      case 'dental':
        return FontAwesomeIcons.tooth;
      case 'eye care':
        return FontAwesomeIcons.glasses;
      default:
        return FontAwesomeIcons.heartPulse;
    }
  }

  Future<void> _saveHealthRecord() async {
    if (_formKey.currentState!.validate()) {
      if (_hasNextVisit && _nextVisit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select next visit date'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      final record = HealthRecord(
        memberName: _memberController.text,
        recordType: _selectedType,
        date: _selectedDate,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        doctorName: _doctorController.text.isEmpty
            ? null
            : _doctorController.text,
        medication: _medicationController.text.isEmpty
            ? null
            : _medicationController.text,
        nextVisit: _nextVisit,
      );

      try {
        await Provider.of<HealthProvider>(
          context,
          listen: false,
        ).addHealthRecord(record);

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Health record added successfully!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving health record: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
