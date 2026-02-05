import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/reminder.dart';
import '../providers/reminder_provider.dart';
import '../utils/app_theme.dart';

class AddReminderDialog extends StatefulWidget {
  final Reminder? reminder;
  final String? initialTitle;

  const AddReminderDialog({super.key, this.reminder, this.initialTitle});

  @override
  State<AddReminderDialog> createState() => _AddReminderDialogState();
}

class _AddReminderDialogState extends State<AddReminderDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _dueDate;
  String _type = 'Bill';
  bool _isRecurring = false;
  String? _recurringType;
  bool _notificationEnabled = true;
  int _notificationDaysBefore = 1;
  bool _isLoading = false;

  final List<String> _types = [
    'Bill',
    'EMI Payment',
    'Mobile Recharge',
    'DTH',
    'Internet Bill',
    'Loan',
    'Subscription',
    'Rent',
    'Insurance',
    'School Fees',
    'Tuition',
    'Education Fee',
    'Credit Card',
    'Medical',
    'Health Checkup',
    'Pet Care',
    'Home Maintenance',
    'Cleaning Supplies',
    'Furniture',
    'Family Outing',
    'Family Dinner',
    'Car Service',
    'Tax Payment',
    'Utility Bills',
    'Custom',
  ];
  final List<String> _recurringTypes = ['Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.reminder?.title ?? widget.initialTitle,
    );
    _amountController = TextEditingController(
      text: widget.reminder?.amount?.toString() ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.reminder?.description,
    );
    _dueDate =
        widget.reminder?.dueDate ?? DateTime.now().add(const Duration(days: 1));
    _type = widget.reminder?.type ?? 'Bill';
    _isRecurring = widget.reminder?.isRecurring ?? false;
    _recurringType = widget.reminder?.recurringType ?? 'Monthly';
    _notificationEnabled = widget.reminder?.notificationEnabled ?? true;
    _notificationDaysBefore = widget.reminder?.notificationDaysBefore ?? 1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
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
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 650),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: FaIcon(
                    widget.reminder == null
                        ? FontAwesomeIcons.bell
                        : FontAwesomeIcons.pen,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reminder == null
                            ? 'New Reminder'
                            : 'Edit Reminder',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        'Set up alerts for bills & payments',
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
                      _buildLabel('Title'),
                      TextFormField(
                        controller: _titleController,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'e.g., Rent Payment',
                          Icons.title,
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Please enter a title'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      _buildLabel('Type'),
                      DropdownButtonFormField<String>(
                        value: _types.contains(_type) ? _type : 'Custom',
                        dropdownColor: cardColor,
                        style: GoogleFonts.inter(color: textPrimary),
                        decoration: _inputDecoration(
                          'Select Type',
                          Icons.category,
                        ),
                        items: _types.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _type = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildLabel('Amount'),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.inter(color: textPrimary),
                                  decoration: _inputDecoration(
                                    '0.00',
                                    Icons.currency_rupee,
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
                                _buildLabel('Due Date'),
                                InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: _dueDate,
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime(2100),
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: AppTheme.primaryColor,
                                              onPrimary: Colors.white,
                                              surface: cardColor,
                                              onSurface: textPrimary,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (picked != null) {
                                      setState(() => _dueDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.withValues(
                                          alpha: 0.2,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 18,
                                          color: textPrimary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            DateFormat(
                                              'MMM d, y',
                                            ).format(_dueDate),
                                            style: GoogleFonts.inter(
                                              color: textPrimary,
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Settings Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            // Recurring Toggle
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.repeat,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Recurring Payment',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _isRecurring,
                                  onChanged: (val) =>
                                      setState(() => _isRecurring = val),
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                            if (_isRecurring) ...[
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _recurringType,
                                dropdownColor: cardColor,
                                style: GoogleFonts.inter(color: textPrimary),
                                decoration: _inputDecoration(
                                  'Frequency',
                                  Icons.update,
                                ),
                                items: _recurringTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _recurringType = val);
                                  }
                                },
                              ),
                            ],
                            const Divider(height: 24),

                            // Notification Toggle
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Colors.blue,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Get Notified',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _notificationEnabled,
                                  onChanged: (val) => setState(
                                    () => _notificationEnabled = val,
                                  ),
                                  activeColor: AppTheme.primaryColor,
                                ),
                              ],
                            ),
                            if (_notificationEnabled) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Text(
                                    'Notify before:',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  Expanded(
                                    child: Slider(
                                      value: _notificationDaysBefore.toDouble(),
                                      min: 1,
                                      max: 7,
                                      divisions: 6,
                                      activeColor: AppTheme.primaryColor,
                                      label: '$_notificationDaysBefore days',
                                      onChanged: (val) => setState(
                                        () => _notificationDaysBefore = val
                                            .toInt(),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '$_notificationDaysBefore d',
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryColor,
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
                    onPressed: _isLoading ? null : _saveReminder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
                            'Save Reminder',
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

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      final reminder = Reminder(
        id: widget.reminder?.id,
        title: _titleController.text,
        type: _type,
        dueDate: _dueDate,
        amount: _amountController.text.isNotEmpty
            ? double.tryParse(_amountController.text)
            : null,
        description: _descriptionController.text,
        isRecurring: _isRecurring,
        recurringType: _isRecurring ? _recurringType : null,
        notificationEnabled: _notificationEnabled,
        notificationDaysBefore: _notificationDaysBefore,
        isPaid: widget.reminder?.isPaid ?? false,
        paidDate: widget.reminder?.paidDate,
      );

      try {
        final provider = Provider.of<ReminderProvider>(context, listen: false);
        if (widget.reminder == null) {
          await provider.addReminder(reminder);
        } else {
          await provider.updateReminder(reminder);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving reminder: $e'),
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
