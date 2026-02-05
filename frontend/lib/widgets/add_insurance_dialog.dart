import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../models/health_record.dart';
import '../providers/health_provider.dart';

class AddInsuranceDialog extends StatefulWidget {
  const AddInsuranceDialog({super.key});

  @override
  State<AddInsuranceDialog> createState() => _AddInsuranceDialogState();
}

class _AddInsuranceDialogState extends State<AddInsuranceDialog> {
  final _formKey = GlobalKey<FormState>();
  final _memberNameController = TextEditingController();
  final _providerController = TextEditingController();
  final _policyNumberController = TextEditingController();
  final _coverageController = TextEditingController();

  DateTime? _validUntil;

  @override
  void dispose() {
    _memberNameController.dispose();
    _providerController.dispose();
    _policyNumberController.dispose();
    _coverageController.dispose();
    super.dispose();
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      final insuranceInfo = InsuranceInfo(
        provider: _providerController.text,
        policyNumber: _policyNumberController.text,
        coverageAmount: double.tryParse(_coverageController.text),
        validUntil: _validUntil,
        policyType: 'Health',
      );

      final record = HealthRecord(
        memberName: _memberNameController.text,
        recordType: 'Insurance',
        date: DateTime.now(),
        insurance: insuranceInfo,
        description: 'Insurance Policy',
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
              content: Text('Insurance policy added!'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        // handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.shieldHeart,
                          color: Colors.green,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Add Insurance',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
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
                controller: _memberNameController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'Family Member Name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _providerController,
                decoration: InputDecoration(
                  labelText: 'Provider (e.g. Aetna, LIC)',
                  prefixIcon: const Icon(Icons.business),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _policyNumberController,
                decoration: InputDecoration(
                  labelText: 'Policy Number',
                  prefixIcon: const Icon(Icons.numbers),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _coverageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Coverage Amount',
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                  ), // Assuming app uses Rupee as per previous context
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate:
                        _validUntil ??
                        DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (d != null) setState(() => _validUntil = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available, color: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Valid Until',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            _validUntil != null
                                ? DateFormat('MMM d, yyyy').format(_validUntil!)
                                : 'Select Date',
                            style: GoogleFonts.inter(fontSize: 14),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Save Policy'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
