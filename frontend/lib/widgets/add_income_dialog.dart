import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/income.dart';
import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class AddIncomeDialog extends StatefulWidget {
  final Income? income;

  const AddIncomeDialog({super.key, this.income});

  @override
  State<AddIncomeDialog> createState() => _AddIncomeDialogState();
}

class _AddIncomeDialogState extends State<AddIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late String _selectedSource;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;
  late bool _isRecurring;
  String? _recurringType;

  final List<String> _sources = [
    'Salary',
    'Business',
    'Investment',
    'Freelance',
    'Rent',
    'Interest',
    'Gift',
    'Bonus',
    'Dividend',
    'Refund',
    'Allowance',
    'Other',
  ];

  final List<String> _recurringTypes = ['monthly', 'weekly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?.description);
    _amountController = TextEditingController(
      text: widget.income?.amount.toString(),
    );
    _descriptionController = TextEditingController(text: widget.income?.notes);
    _selectedSource = widget.income?.source ?? 'Salary';
    _selectedPaymentMethod = widget.income?.paymentMethod ?? 'Bank Transfer';
    _selectedDate = widget.income?.date ?? DateTime.now();
    _isRecurring = widget.income?.isRecurring ?? false;
    _recurringType = widget.income?.recurringType;
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
                          color: AppTheme.successColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.moneyBillTrendUp,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.income == null ? 'Add Income' : 'Edit Income',
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
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Monthly Salary',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedSource,
                decoration: const InputDecoration(
                  labelText: 'Source',
                  prefixIcon: Icon(Icons.source),
                ),
                items: _sources.map((source) {
                  return DropdownMenuItem(value: source, child: Text(source));
                }).toList(),
                onChanged: (value) => setState(() => _selectedSource = value!),
                dropdownColor: Theme.of(context).cardColor,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add notes',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                decoration: const InputDecoration(
                  labelText: 'Received Via',
                  prefixIcon: Icon(Icons.payment),
                ),
                items: ['Bank Transfer', 'Cash', 'Cheque', 'UPI', 'Other'].map((
                  method,
                ) {
                  return DropdownMenuItem(value: method, child: Text(method));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                dropdownColor: Theme.of(context).cardColor,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _selectedDate = date);
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
                      Text(
                        '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              CheckboxListTile(
                value: _isRecurring,
                onChanged: (value) {
                  setState(() {
                    _isRecurring = value ?? false;
                    if (!_isRecurring) _recurringType = null;
                  });
                },
                title: const Text('Recurring Income'),
                contentPadding: EdgeInsets.zero,
                activeColor: AppTheme.successColor,
              ),

              if (_isRecurring) ...[
                DropdownButtonFormField<String>(
                  initialValue: _recurringType,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    prefixIcon: Icon(Icons.repeat),
                  ),
                  items: _recurringTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type[0].toUpperCase() + type.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _recurringType = value),
                  dropdownColor: Theme.of(context).cardColor,
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.income == null ? 'Add Income' : 'Update Income',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveIncome() {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && _recurringType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select frequency for recurring income'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }

      final income = Income(
        id: widget
            .income
            ?.id, // Don't generate UUID - let MongoDB create the _id
        description: _titleController.text,
        amount: double.parse(_amountController.text),
        source: _selectedSource,
        date: _selectedDate,
        notes: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        isRecurring: _isRecurring,
        recurringFrequency: _recurringType,
      );

      final provider = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );

      if (widget.income == null) {
        provider.addIncome(income);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income added successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      } else {
        provider.updateIncome(income);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income updated successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      Navigator.pop(context);
    }
  }
}
