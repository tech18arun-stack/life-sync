/// Income model for Supabase
class Income {
  String? id;
  String? userId;
  String description;
  double amount;
  String source;
  DateTime date;
  bool isRecurring;
  String? recurringFrequency;
  String? notes;
  String? familyMemberId;
  String? contactName;
  String? phoneNumber;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Backward compatibility getters
  String get title => description;
  String? get paymentMethod => null; // Not used in backend
  String? get recurringType => recurringFrequency;

  Income({
    this.id,
    this.userId,
    required this.description,
    required this.amount,
    required this.source,
    required this.date,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notes,
    this.familyMemberId,
    this.contactName,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      userId: json['user_id'],
      description: json['description'] ?? json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      source: json['source'] ?? 'Other',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isRecurring: json['is_recurring'] ?? false,
      recurringFrequency: json['recurring_frequency'] ?? json['recurring_type'],
      notes: json['notes'],
      familyMemberId: json['family_member_id'],
      contactName: json['contact_name'],
      phoneNumber: json['phone_number'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'description': description,
      'amount': amount,
      'source': source,
      'date': date.toIso8601String(),
      'is_recurring': isRecurring,
      if (recurringFrequency != null) 'recurring_frequency': recurringFrequency,
      if (notes != null) 'notes': notes,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      if (contactName != null) 'contact_name': contactName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  Income copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    String? source,
    DateTime? date,
    bool? isRecurring,
    String? recurringFrequency,
    String? notes,
    String? familyMemberId,
    String? contactName,
    String? phoneNumber,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      notes: notes ?? this.notes,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
