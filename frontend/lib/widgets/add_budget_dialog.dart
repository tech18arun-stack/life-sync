import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/budget.dart';
import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';

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
    'Food & Dining',
    'Groceries',
    'Vegetables',
    'Fruits',
    'Meat',
    'Dairy',
    'Transportation',
    'Utilities',
    'Bills',
    'Mobile Recharge',
    'DTH',
    'Internet Bill',
    'Health & Fitness',
    'Education',
    'School Fees',
    'Tuition',
    'Education Fee',
    'Entertainment',
    'Subscription',
    'Shopping',
    'Gadgets',
    'Personal Care',
    'Gifts & Donations',
    'Charity',
    'Wedding',
    'Investments',
    'Retirement',
    'Business',
    'Debt Payments',
    'Loan',
    'EMI',
    'Credit Card',
    'Travel',
    'Vacation',
    'Kids',
    'Childcare',
    'Pets',
    'Pet Care',
    'Housing',
    'Rent',
    'Home',
    'Household',
    'Home Maintenance',
    'Cleaning Supplies',
    'Furniture',
    'Family',
    'Family Outing',
    'Family Dinner',
    'Car',
    'Insurance',
    'Emergency Fund',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.budget?.category);
    _amountController = TextEditingController(
      text: widget.budget?.allocatedAmount.toString(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textPrimary =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final textSecondary =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.grey;
    final inputFillColor = isDark
        ? Colors.grey.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.05);

    return Dialog(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 10,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.budget == null ? 'Set Budget' : 'Edit Budget',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textSecondary),
                    style: IconButton.styleFrom(
                      backgroundColor: inputFillColor,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category
              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                value:
                    (_categoryController.text.isNotEmpty &&
                        _categories.contains(_categoryController.text))
                    ? _categoryController.text
                    : null,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  'Select category',
                  Icons.category,
                  inputFillColor,
                  textSecondary,
                ),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _categoryController.text = val);
                  }
                },
                validator: (val) =>
                    val == null || val.isEmpty ? 'Select a category' : null,
              ),
              const SizedBox(height: 16),

              // Amount
              _buildLabel('Limit Amount'),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  '0.00',
                  FontAwesomeIcons.indianRupeeSign,
                  inputFillColor,
                  textSecondary,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Enter amount';
                  }
                  if (double.tryParse(val) == null) {
                    return 'Invalid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Period
              _buildLabel('Period'),
              DropdownButtonFormField<String>(
                value: _period,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  '',
                  Icons.refresh,
                  inputFillColor,
                  textSecondary,
                ),
                items: _periods
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _period = val;
                      // Auto adjust end date
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

              // Dates
              _buildLabel('Duration'),
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
                            if (_endDate.isBefore(_startDate)) {
                              _endDate = _startDate.add(
                                const Duration(days: 1),
                              );
                            }
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Starts',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y').format(_startDate),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
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
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ends',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, y').format(_endDate),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Alert Settings
              Container(
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(8),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Alert me',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'When spending exceeds limit',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                      value: _alertEnabled,
                      activeColor: AppTheme.primaryColor,
                      onChanged: (val) => setState(() => _alertEnabled = val),
                    ),
                    if (_alertEnabled) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Threshold:',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppTheme.primaryColor,
                                  thumbColor: AppTheme.primaryColor,
                                  inactiveTrackColor: Colors.grey.withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                                child: Slider(
                                  value: _alertThreshold,
                                  min: 50,
                                  max: 100,
                                  divisions: 10,
                                  label: '${_alertThreshold.round()}%',
                                  onChanged: (val) =>
                                      setState(() => _alertThreshold = val),
                                ),
                              ),
                            ),
                            Text(
                              '${_alertThreshold.round()}%',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    widget.budget == null ? 'Create Budget' : 'Update Budget',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    IconData icon,
    Color fillColor,
    Color iconColor,
  ) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _saveBudget() async {
    if (_formKey.currentState!.validate()) {
      final budget = Budget(
        id: widget.budget?.id,
        category: _categoryController.text,
        allocatedAmount: double.parse(_amountController.text),
        spentAmount: widget.budget?.spentAmount ?? 0,
        month: _startDate.month,
        year: _startDate.year,
        alertThreshold: _alertEnabled ? _alertThreshold : 0,
      );

      final manager = Provider.of<FinancialDataManager>(context, listen: false);

      try {
        if (widget.budget == null) {
          await manager.addBudget(budget);
        } else {
          await manager.updateBudget(budget);
        }
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }
}
