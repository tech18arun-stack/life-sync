import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/expense.dart';
import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';

class AddExpenseDialog extends StatefulWidget {
  final Expense? expense;

  const AddExpenseDialog({super.key, this.expense});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late String _selectedCategory;
  late String _selectedPaymentMethod;
  late DateTime _selectedDate;

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
    _titleController = TextEditingController(text: widget.expense?.description);
    _amountController = TextEditingController(
      text: widget.expense != null ? widget.expense!.amount.toString() : '',
    );
    _descriptionController = TextEditingController(text: widget.expense?.notes);
    _selectedCategory = widget.expense?.category ?? _categories.first;
    // Validate category exists
    if (!_categories.contains(_selectedCategory)) {
      _selectedCategory = _categories.first;
    }
    _selectedPaymentMethod = widget.expense?.paymentMethod ?? 'Cash';
    _selectedDate = widget.expense?.date ?? DateTime.now();
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
                    widget.expense == null ? 'New Expense' : 'Edit Expense',
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

              // Title Input
              _buildLabel('Title'),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                  'e.g., Grocery Shopping',
                  Icons.edit,
                  inputFillColor,
                  textSecondary,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Amount Input
              _buildLabel('Amount'),
              TextFormField(
                controller: _amountController,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDecoration(
                  '0.00',
                  FontAwesomeIcons.indianRupeeSign,
                  inputFillColor,
                  textSecondary,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an amount';
                  }
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              _buildLabel('Category'),
              DropdownButtonFormField<String>(
                initialValue: _categories.contains(_selectedCategory)
                    ? _selectedCategory
                    : _categories.first,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  '',
                  Icons.category,
                  inputFillColor,
                  textSecondary,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: AppTheme.getCategoryColor(category),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),

              // Payment Method
              _buildLabel('Payment Method'),
              DropdownButtonFormField<String>(
                initialValue: _selectedPaymentMethod,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  '',
                  Icons.payment,
                  inputFillColor,
                  textSecondary,
                ),
                items: ['Cash', 'UPI', 'Card', 'Net Banking', 'Other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedPaymentMethod = val!),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker
              _buildLabel('Date & Time'),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(
                            () => _selectedDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              _selectedDate.hour,
                              _selectedDate.minute,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 18,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('MMM d, y').format(_selectedDate),
                                style: GoogleFonts.inter(color: textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedDate),
                        );
                        if (time != null) {
                          setState(
                            () => _selectedDate = DateTime(
                              _selectedDate.year,
                              _selectedDate.month,
                              _selectedDate.day,
                              time.hour,
                              time.minute,
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: inputFillColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateFormat('h:mm a').format(_selectedDate),
                                style: GoogleFonts.inter(color: textPrimary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              _buildLabel('Notes (Optional)'),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.inter(color: textPrimary),
                maxLines: 2,
                decoration: _inputDecoration(
                  'Add any extra details...',
                  Icons.notes,
                  inputFillColor,
                  textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorColor, // Red for expense
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.errorColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    widget.expense == null ? 'Add Expense' : 'Update Expense',
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

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      final expense = Expense(
        id: widget.expense?.id,
        description: _titleController.text,
        amount: double.parse(_amountController.text),
        category: _selectedCategory,
        date: _selectedDate,
        notes: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        paymentMethod: _selectedPaymentMethod,
      );

      final provider = Provider.of<FinancialDataManager>(
        context,
        listen: false,
      );

      try {
        if (widget.expense == null) {
          await provider.addExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense added!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        } else {
          await provider.updateExpense(expense);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Expense updated!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
          }
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }
}
