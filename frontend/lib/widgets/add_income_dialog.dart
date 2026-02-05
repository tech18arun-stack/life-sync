import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/income.dart';
import '../providers/financial_data_manager.dart';
import '../utils/app_theme.dart';

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
    'Pension',
    'Stipend',
    'Commission',
    'Royalties',
    'Side Hustle',
    'Online Business',
    'Part-time Job',
    'Contract Work',
    'Consulting',
    'Teaching',
    'Tutoring',
    'Selling Products',
    'Selling Services',
    'Rental Income',
    'Tips',
    'Tax Refund',
    'Insurance Payout',
    'Legal Settlement',
    'Inheritance',
    'Other',
  ];

  final List<String> _recurringTypes = ['monthly', 'weekly', 'yearly'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.income?.description);
    _amountController = TextEditingController(
      text: widget.income != null ? widget.income!.amount.toString() : '',
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.moneyBillTrendUp,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.income == null ? 'New Income' : 'Edit Income',
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                    ],
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

              // Title
              _buildLabel('Title'),
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.inter(
                  color: textPrimary,
                  fontWeight: FontWeight.w500,
                ),
                decoration: _inputDecoration(
                  'e.g., Monthly Salary',
                  Icons.edit,
                  inputFillColor,
                  textSecondary,
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter a title'
                    : null,
              ),
              const SizedBox(height: 16),

              // Amount
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
                  if (value == null || value.isEmpty)
                    return 'Please enter an amount';
                  if (double.tryParse(value) == null) return 'Invalid number';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Source
              _buildLabel('Source'),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  '',
                  Icons.source,
                  inputFillColor,
                  textSecondary,
                ),
                items: _sources
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedSource = val!),
              ),
              const SizedBox(height: 16),

              // Payment Method
              _buildLabel('Received Via'),
              DropdownButtonFormField<String>(
                value: _selectedPaymentMethod,
                dropdownColor: cardColor,
                style: GoogleFonts.inter(color: textPrimary),
                decoration: _inputDecoration(
                  '',
                  Icons.payment,
                  inputFillColor,
                  textSecondary,
                ),
                items: ['Bank Transfer', 'Cash', 'Cheque', 'UPI', 'Other']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedPaymentMethod = val!),
              ),
              const SizedBox(height: 16),

              // Date
              _buildLabel('Date'),
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
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_selectedDate),
                          style: GoogleFonts.inter(
                            color: textPrimary,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Recurring Options
              Container(
                decoration: BoxDecoration(
                  color: inputFillColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  title: Text(
                    'Recurring Income',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  value: _isRecurring,
                  activeColor: AppTheme.successColor,
                  onChanged: (val) {
                    setState(() {
                      _isRecurring = val;
                      if (!_isRecurring)
                        _recurringType = null;
                      else
                        _recurringType = 'monthly'; // default
                    });
                  },
                ),
              ),
              if (_isRecurring) ...[
                const SizedBox(height: 12),
                _buildLabel('Frequency'),
                DropdownButtonFormField<String>(
                  value: _recurringType ?? 'monthly',
                  dropdownColor: cardColor,
                  style: GoogleFonts.inter(color: textPrimary),
                  decoration: _inputDecoration(
                    '',
                    Icons.repeat,
                    inputFillColor,
                    textSecondary,
                  ),
                  items: _recurringTypes
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t[0].toUpperCase() + t.substring(1)),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setState(() => _recurringType = val),
                ),
              ],
              const SizedBox(height: 16),

              // Notes
              _buildLabel('Notes (Optional)'),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.inter(color: textPrimary),
                maxLines: 2,
                decoration: _inputDecoration(
                  'Add notes...',
                  Icons.notes,
                  inputFillColor,
                  textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveIncome,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: AppTheme.successColor.withValues(alpha: 0.4),
                  ),
                  child: Text(
                    widget.income == null ? 'Add Income' : 'Update Income',
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
        borderSide: BorderSide(color: AppTheme.successColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  Future<void> _saveIncome() async {
    if (_formKey.currentState!.validate()) {
      if (_isRecurring && _recurringType == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Select frequency'),
            backgroundColor: AppTheme.warningColor,
          ),
        );
        return;
      }
      final income = Income(
        id: widget.income?.id,
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

      try {
        if (widget.income == null) {
          await provider.addIncome(income);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Income added!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
        } else {
          await provider.updateIncome(income);
          if (mounted)
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Income updated!'),
                backgroundColor: AppTheme.successColor,
              ),
            );
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
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
