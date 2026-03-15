import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../models/health_record.dart';
import '../providers/health_provider.dart';
import '../utils/app_theme.dart';

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
  bool _isLoading = false;

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
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardColor;

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.healthColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.heartPulse,
                    color: AppTheme.healthColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Health Record',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Track medical visits & history',
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
            const SizedBox(height: 24),

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Family Member'),
                      TextFormField(
                        controller: _memberController,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'e.g., John Doe',
                          Icons.person,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter family member name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Record Type'),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        dropdownColor: cardColor,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'Select Type',
                          Icons.medical_services,
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
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'Details about the visit',
                          Icons.notes,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Doctor Name (Optional)'),
                      TextFormField(
                        controller: _doctorController,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'Dr. Name',
                          Icons.local_hospital,
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Medication (Optional)'),
                      TextFormField(
                        controller: _medicationController,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'Prescribed medicines',
                          Icons.medication,
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Record Date'),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.healthColor,
                                    onPrimary: Colors.white,
                                    surface: cardColor,
                                    onSurface: textPrimary,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            setState(() {
                              _selectedDate = date;
                            });
                          }
                        },
                        child: _buildDateContainer(
                          _selectedDate,
                          Icons.calendar_today,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Next Visit Toggle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: CheckboxListTile(
                          value: _hasNextVisit,
                          onChanged: (value) {
                            setState(() {
                              _hasNextVisit = value ?? false;
                              if (!_hasNextVisit) {
                                _nextVisit = null;
                              }
                            });
                          },
                          title: Text(
                            'Schedule Next Visit',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          activeColor: AppTheme.healthColor,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ),

                      if (_hasNextVisit) ...[
                        const SizedBox(height: 16),
                        _buildLabel('Next Visit Date'),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(
                                const Duration(days: 7),
                              ),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(
                                const Duration(days: 365),
                              ),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppTheme.healthColor,
                                      onPrimary: Colors.white,
                                      surface: cardColor,
                                      onSurface: textPrimary,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (date != null) {
                              setState(() {
                                _nextVisit = date;
                              });
                            }
                          },
                          child: _buildDateContainer(
                            _nextVisit,
                            FontAwesomeIcons.calendarCheck,
                            isPlaceholder: _nextVisit == null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveHealthRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.healthColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save Record',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Theme.of(context).scaffoldBackgroundColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildDateContainer(
    DateTime? date,
    IconData icon, {
    bool isPlaceholder = false,
  }) {
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isPlaceholder
                ? Colors.grey
                : textPrimary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 12),
          Text(
            date != null ? DateFormat('MMM d, y').format(date) : 'Select Date',
            style: GoogleFonts.inter(
              color: isPlaceholder ? Colors.grey : textPrimary,
              fontWeight: isPlaceholder ? FontWeight.normal : FontWeight.w500,
            ),
          ),
        ],
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
      setState(() => _isLoading = true);

      if (_hasNextVisit && _nextVisit == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please select next visit date',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        setState(() => _isLoading = false);
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
            SnackBar(
              content: Text(
                'Health record added successfully!',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error saving health record: $e',
                style: GoogleFonts.inter(),
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }
}
