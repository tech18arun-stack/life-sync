import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/reminder.dart';
import '../providers/reminder_provider.dart';

class AddReminderDialog extends StatefulWidget {
  final Reminder? reminder;

  const AddReminderDialog({super.key, this.reminder});

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

  final List<String> _types = [
    'Bill',
    'EMI',
    'Recharge',
    'Loan',
    'Subscription',
    'Rent',
    'Insurance',
    'School Fees',
    'Credit Card',
    'Medical',
    'Custom',
  ];
  final List<String> _recurringTypes = ['Weekly', 'Monthly', 'Yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title);
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
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.reminder == null ? 'Add Reminder' : 'Edit Reminder',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Electricity Bill',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Type
              DropdownButtonFormField<String>(
                initialValue: _types.contains(_type) ? _type : 'Custom',
                decoration: const InputDecoration(
                  labelText: 'Type',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _type = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (Optional)',
                  prefixIcon: Icon(Icons.attach_money),
                ),
              ),
              const SizedBox(height: 16),

              // Due Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    prefixIcon: Icon(Icons.event),
                  ),
                  child: Text(DateFormat('EEE, MMM d, y').format(_dueDate)),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Settings
              SwitchListTile(
                title: const Text('Recurring'),
                value: _isRecurring,
                onChanged: (value) => setState(() => _isRecurring = value),
                contentPadding: EdgeInsets.zero,
              ),

              if (_isRecurring)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: _recurringType,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(Icons.repeat),
                    ),
                    items: _recurringTypes.map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _recurringType = value);
                      }
                    },
                  ),
                ),

              // Notification Settings
              SwitchListTile(
                title: const Text('Enable Notification'),
                value: _notificationEnabled,
                onChanged: (value) =>
                    setState(() => _notificationEnabled = value),
                contentPadding: EdgeInsets.zero,
              ),

              if (_notificationEnabled) ...[
                Text(
                  'Notify $_notificationDaysBefore day(s) before',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _notificationDaysBefore.toDouble(),
                  min: 1,
                  max: 7,
                  divisions: 6,
                  label: '$_notificationDaysBefore days',
                  onChanged: (value) =>
                      setState(() => _notificationDaysBefore = value.toInt()),
                ),
              ],

              const SizedBox(height: 24),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _saveReminder,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate()) {
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
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
