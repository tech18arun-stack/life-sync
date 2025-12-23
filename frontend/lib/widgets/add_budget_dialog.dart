import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget.dart';
import '../providers/financial_data_manager.dart';

class AddBudgetDialog extends StatefulWidget {
  final Budget? budget;

  const AddBudgetDialog({super.key, this.budget});

  @override
  State<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends State<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryController;
  late TextEditingController _amountController;
  late DateTime _startDate;
  late DateTime _endDate;
  String _period = 'Monthly';
  bool _alertEnabled = true;
  double _alertThreshold = 80;

  final List<String> _periods = ['Weekly', 'Monthly', 'Yearly'];
  final List<String> _categories = [
    'Housing',
    'Transportation',
    'Food & Dining',
    'Utilities',
    'Health & Fitness',
    'Education',
    'Entertainment',
    'Shopping',
    'Personal Care',
    'Gifts & Donations',
    'Investments',
    'Debt Payments',
    'Travel',
    'Kids',
    'Pets',
    'Insurance',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.budget?.category);
    _amountController = TextEditingController(
      text: widget.budget?.allocatedAmount.toString() ?? '',
    );
    _startDate = widget.budget?.startDate ?? DateTime.now();
    _endDate =
        widget.budget?.endDate ?? DateTime.now().add(const Duration(days: 30));
    _period = widget.budget?.period ?? 'Monthly';
    _alertEnabled = widget.budget?.alertEnabled ?? true;
    _alertThreshold = widget.budget?.alertThreshold ?? 80;
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
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
                widget.budget == null ? 'Add Budget' : 'Edit Budget',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue:
                    _categoryController.text.isNotEmpty &&
                        _categories.contains(_categoryController.text)
                    ? _categoryController.text
                    : null,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  prefixIcon: Icon(Icons.category),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _categoryController.text = value;
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Please select a category'
                    : null,
              ),
              const SizedBox(height: 16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixIcon: Icon(Icons.attach_money),
                ),
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

              // Period
              DropdownButtonFormField<String>(
                initialValue: _period,
                decoration: const InputDecoration(
                  labelText: 'Period',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                items: _periods.map((period) {
                  return DropdownMenuItem(value: period, child: Text(period));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _period = value;
                      // Auto-adjust end date based on period
                      if (_period == 'Weekly') {
                        _endDate = _startDate.add(const Duration(days: 7));
                      } else if (_period == 'Monthly') {
                        _endDate = DateTime(
                          _startDate.year,
                          _startDate.month + 1,
                          _startDate.day,
                        );
                      } else if (_period == 'Yearly') {
                        _endDate = DateTime(
                          _startDate.year + 1,
                          _startDate.month,
                          _startDate.day,
                        );
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Date Range
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked;
                            // Adjust end date to be at least start date
                            if (_endDate.isBefore(_startDate)) {
                              _endDate = _startDate.add(
                                const Duration(days: 1),
                              );
                            }
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.date_range),
                        ),
                        child: Text(
                          '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: _startDate,
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.event),
                        ),
                        child: Text(
                          '${_endDate.day}/${_endDate.month}/${_endDate.year}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Alert Settings
              SwitchListTile(
                title: const Text('Enable Alerts'),
                subtitle: const Text('Notify when budget is exceeded'),
                value: _alertEnabled,
                onChanged: (value) => setState(() => _alertEnabled = value),
                contentPadding: EdgeInsets.zero,
              ),

              if (_alertEnabled) ...[
                Text(
                  'Alert Threshold: ${_alertThreshold.round()}%',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Slider(
                  value: _alertThreshold,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${_alertThreshold.round()}%',
                  onChanged: (value) => setState(() => _alertThreshold = value),
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _saveBudget,
                    child: const Text('Save Budget'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveBudget() {
    if (_formKey.currentState!.validate()) {
      final budget = Budget(
        id: widget
            .budget
            ?.id, // Don't generate UUID - let MongoDB create the _id
        category: _categoryController.text,
        allocatedAmount: double.parse(_amountController.text),
        spentAmount: widget.budget?.spentAmount ?? 0,
        month: _startDate.month,
        year: _startDate.year,
        alertThreshold: _alertEnabled ? _alertThreshold : 0,
      );

      final manager = Provider.of<FinancialDataManager>(context, listen: false);
      if (widget.budget == null) {
        manager.addBudget(budget);
      } else {
        manager.updateBudget(budget);
      }

      Navigator.pop(context);
    }
  }
}
