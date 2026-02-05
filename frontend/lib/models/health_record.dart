/// HealthRecord model with comprehensive health tracking
class HealthRecord {
  String? id;
  String? userId;
  String memberName;
  String
  recordType; // Checkup, Vaccination, Medication, Lab Test, Vitals, Surgery, Allergy, Insurance, Other
  DateTime date;
  String? description;
  String? doctorName;
  String? hospitalName;
  String? medication;
  String? dosage;
  String? frequency;
  DateTime? nextVisit;
  String? notes;
  bool isActive;

  // Vitals
  Vitals? vitals;

  // Lab Results
  LabResult? labResults;

  // Allergy Information
  AllergyInfo? allergy;

  // Insurance Details
  InsuranceInfo? insurance;

  // Blood Type
  String? bloodType;

  // Vaccination specific
  String? vaccineDose;
  String? vaccineManufacturer;
  String? batchNumber;

  List<String>? attachments;

  HealthRecord({
    this.id,
    this.userId,
    required this.memberName,
    required this.recordType,
    required this.date,
    this.description,
    this.doctorName,
    this.hospitalName,
    this.medication,
    this.dosage,
    this.frequency,
    this.nextVisit,
    this.notes,
    this.isActive = true,
    this.vitals,
    this.labResults,
    this.allergy,
    this.insurance,
    this.bloodType,
    this.vaccineDose,
    this.vaccineManufacturer,
    this.batchNumber,
    this.attachments,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'member_name': memberName,
      'record_type': recordType,
      'date': date.toIso8601String().split('T')[0], // Date only for DATE column
      if (description != null) 'description': description,
      if (doctorName != null) 'doctor_name': doctorName,
      if (hospitalName != null) 'hospital_name': hospitalName,
      if (medication != null) 'medication': medication,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (nextVisit != null)
        'next_visit': nextVisit!.toIso8601String().split('T')[0],
      if (notes != null) 'notes': notes,
      if (attachments != null) 'attachments': attachments,
    };
  }

  factory HealthRecord.fromJson(Map<String, dynamic> json) {
    return HealthRecord(
      id: json['id'] ?? json['_id'],
      userId: json['user_id'] ?? json['userId'],
      memberName: json['member_name'] ?? json['memberName'] ?? '',
      recordType: json['record_type'] ?? json['recordType'] ?? 'Checkup',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      description: json['description'],
      doctorName: json['doctor_name'] ?? json['doctorName'],
      hospitalName: json['hospital_name'] ?? json['hospitalName'],
      medication: json['medication'],
      dosage: json['dosage'],
      frequency: json['frequency'],
      nextVisit: json['next_visit'] != null
          ? DateTime.parse(json['next_visit'])
          : (json['nextVisit'] != null
                ? DateTime.parse(json['nextVisit'])
                : null),
      notes: json['notes'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      vitals: json['vitals'] != null ? Vitals.fromJson(json['vitals']) : null,
      labResults: json['labResults'] != null
          ? LabResult.fromJson(json['labResults'])
          : null,
      allergy: json['allergy'] != null
          ? AllergyInfo.fromJson(json['allergy'])
          : null,
      insurance: json['insurance'] != null
          ? InsuranceInfo.fromJson(json['insurance'])
          : null,
      bloodType: json['blood_type'] ?? json['bloodType'],
      vaccineDose: json['vaccine_dose'] ?? json['vaccineDose'],
      vaccineManufacturer:
          json['vaccine_manufacturer'] ?? json['vaccineManufacturer'],
      batchNumber: json['batch_number'] ?? json['batchNumber'],
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
    );
  }

  HealthRecord copyWith({
    String? id,
    String? userId,
    String? memberName,
    String? recordType,
    DateTime? date,
    String? description,
    String? doctorName,
    String? hospitalName,
    String? medication,
    String? dosage,
    String? frequency,
    DateTime? nextVisit,
    String? notes,
    bool? isActive,
    Vitals? vitals,
    LabResult? labResults,
    AllergyInfo? allergy,
    InsuranceInfo? insurance,
    String? bloodType,
    String? vaccineDose,
    String? vaccineManufacturer,
    String? batchNumber,
    List<String>? attachments,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      memberName: memberName ?? this.memberName,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      description: description ?? this.description,
      doctorName: doctorName ?? this.doctorName,
      hospitalName: hospitalName ?? this.hospitalName,
      medication: medication ?? this.medication,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      nextVisit: nextVisit ?? this.nextVisit,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      vitals: vitals ?? this.vitals,
      labResults: labResults ?? this.labResults,
      allergy: allergy ?? this.allergy,
      insurance: insurance ?? this.insurance,
      bloodType: bloodType ?? this.bloodType,
      vaccineDose: vaccineDose ?? this.vaccineDose,
      vaccineManufacturer: vaccineManufacturer ?? this.vaccineManufacturer,
      batchNumber: batchNumber ?? this.batchNumber,
      attachments: attachments ?? this.attachments,
    );
  }
}

/// Vitals tracking class
class Vitals {
  double? bloodPressureSystolic;
  double? bloodPressureDiastolic;
  double? heartRate;
  double? temperature;
  double? weight;
  double? height;
  double? bmi;
  double? bloodSugar;
  double? oxygenLevel;

  Vitals({
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.heartRate,
    this.temperature,
    this.weight,
    this.height,
    this.bmi,
    this.bloodSugar,
    this.oxygenLevel,
  });

  // Calculate BMI if weight and height are available
  double? calculateBMI() {
    if (weight != null && height != null && height! > 0) {
      final heightInMeters = height! / 100;
      return weight! / (heightInMeters * heightInMeters);
    }
    return null;
  }

  String getBMICategory() {
    final bmiValue = bmi ?? calculateBMI();
    if (bmiValue == null) return 'Unknown';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  String getBloodPressureCategory() {
    if (bloodPressureSystolic == null || bloodPressureDiastolic == null) {
      return 'Unknown';
    }
    if (bloodPressureSystolic! < 120 && bloodPressureDiastolic! < 80) {
      return 'Normal';
    }
    if (bloodPressureSystolic! < 130 && bloodPressureDiastolic! < 80) {
      return 'Elevated';
    }
    if (bloodPressureSystolic! < 140 || bloodPressureDiastolic! < 90) {
      return 'High (Stage 1)';
    }
    return 'High (Stage 2)';
  }

  Map<String, dynamic> toJson() {
    return {
      if (bloodPressureSystolic != null)
        'bloodPressureSystolic': bloodPressureSystolic,
      if (bloodPressureDiastolic != null)
        'bloodPressureDiastolic': bloodPressureDiastolic,
      if (heartRate != null) 'heartRate': heartRate,
      if (temperature != null) 'temperature': temperature,
      if (weight != null) 'weight': weight,
      if (height != null) 'height': height,
      if (bmi != null) 'bmi': bmi,
      if (bloodSugar != null) 'bloodSugar': bloodSugar,
      if (oxygenLevel != null) 'oxygenLevel': oxygenLevel,
    };
  }

  factory Vitals.fromJson(Map<String, dynamic> json) {
    return Vitals(
      bloodPressureSystolic: (json['bloodPressureSystolic'] as num?)
          ?.toDouble(),
      bloodPressureDiastolic: (json['bloodPressureDiastolic'] as num?)
          ?.toDouble(),
      heartRate: (json['heartRate'] as num?)?.toDouble(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      bloodSugar: (json['bloodSugar'] as num?)?.toDouble(),
      oxygenLevel: (json['oxygenLevel'] as num?)?.toDouble(),
    );
  }
}

/// Lab Result class
class LabResult {
  String? testName;
  String? result;
  String? normalRange;
  String? unit;

  LabResult({this.testName, this.result, this.normalRange, this.unit});

  Map<String, dynamic> toJson() {
    return {
      if (testName != null) 'testName': testName,
      if (result != null) 'result': result,
      if (normalRange != null) 'normalRange': normalRange,
      if (unit != null) 'unit': unit,
    };
  }

  factory LabResult.fromJson(Map<String, dynamic> json) {
    return LabResult(
      testName: json['testName'],
      result: json['result'],
      normalRange: json['normalRange'],
      unit: json['unit'],
    );
  }
}

/// Allergy Information class
class AllergyInfo {
  String? allergen;
  String? severity; // Mild, Moderate, Severe
  String? reactions;
  String? treatment;

  AllergyInfo({this.allergen, this.severity, this.reactions, this.treatment});

  Map<String, dynamic> toJson() {
    return {
      if (allergen != null) 'allergen': allergen,
      if (severity != null) 'severity': severity,
      if (reactions != null) 'reactions': reactions,
      if (treatment != null) 'treatment': treatment,
    };
  }

  factory AllergyInfo.fromJson(Map<String, dynamic> json) {
    return AllergyInfo(
      allergen: json['allergen'],
      severity: json['severity'],
      reactions: json['reactions'],
      treatment: json['treatment'],
    );
  }
}

/// Insurance Information class
class InsuranceInfo {
  String? policyNumber;
  String? provider;
  DateTime? validUntil;
  double? coverageAmount;
  String? policyType;

  InsuranceInfo({
    this.policyNumber,
    this.provider,
    this.validUntil,
    this.coverageAmount,
    this.policyType,
  });

  bool get isExpired =>
      validUntil != null && validUntil!.isBefore(DateTime.now());

  int get daysUntilExpiry {
    if (validUntil == null) return 0;
    return validUntil!.difference(DateTime.now()).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      if (policyNumber != null) 'policyNumber': policyNumber,
      if (provider != null) 'provider': provider,
      if (validUntil != null) 'validUntil': validUntil!.toIso8601String(),
      if (coverageAmount != null) 'coverageAmount': coverageAmount,
      if (policyType != null) 'policyType': policyType,
    };
  }

  factory InsuranceInfo.fromJson(Map<String, dynamic> json) {
    return InsuranceInfo(
      policyNumber: json['policyNumber'],
      provider: json['provider'],
      validUntil: json['validUntil'] != null
          ? DateTime.parse(json['validUntil'])
          : null,
      coverageAmount: (json['coverageAmount'] as num?)?.toDouble(),
      policyType: json['policyType'],
    );
  }
}
