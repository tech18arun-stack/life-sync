/// Income model for MongoDB
class Income {
  String? id;
  String description;
  double amount;
  String source;
  DateTime date;
  bool isRecurring;
  String? recurringFrequency;
  String? notes;
  String? familyMemberId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Backward compatibility getters
  String get title => description;
  String? get paymentMethod => null; // Not used in backend
  String? get recurringType => recurringFrequency;

  Income({
    this.id,
    required this.description,
    required this.amount,
    required this.source,
    required this.date,
    this.isRecurring = false,
    this.recurringFrequency,
    this.notes,
    this.familyMemberId,
    this.createdAt,
    this.updatedAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['_id'] ?? json['id'],
      description: json['description'] ?? json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      source: json['source'] ?? 'Other',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      isRecurring: json['isRecurring'] ?? false,
      recurringFrequency: json['recurringFrequency'] ?? json['recurringType'],
      notes: json['notes'],
      familyMemberId: json['familyMemberId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'description': description,
      'amount': amount,
      'source': source,
      'date': date.toIso8601String(),
      'isRecurring': isRecurring,
      if (recurringFrequency != null) 'recurringFrequency': recurringFrequency,
      if (notes != null) 'notes': notes,
      if (familyMemberId != null) 'familyMemberId': familyMemberId,
    };
  }

  Income copyWith({
    String? id,
    String? description,
    double? amount,
    String? source,
    DateTime? date,
    bool? isRecurring,
    String? recurringFrequency,
    String? notes,
    String? familyMemberId,
  }) {
    return Income(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      source: source ?? this.source,
      date: date ?? this.date,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringFrequency: recurringFrequency ?? this.recurringFrequency,
      notes: notes ?? this.notes,
      familyMemberId: familyMemberId ?? this.familyMemberId,
    );
  }
}
