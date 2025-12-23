/// Expense model for MongoDB
class Expense {
  String? id;
  String description;
  double amount;
  String category;
  DateTime date;
  String? paymentMethod;
  String? notes;
  String? familyMemberId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Backward compatibility getter
  String get title => description;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.notes,
    this.familyMemberId,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'] ?? json['id'],
      description: json['description'] ?? json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      paymentMethod: json['paymentMethod'],
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
      'category': category,
      'date': date.toIso8601String(),
      if (paymentMethod != null) 'paymentMethod': paymentMethod,
      if (notes != null) 'notes': notes,
      if (familyMemberId != null) 'familyMemberId': familyMemberId,
    };
  }

  Expense copyWith({
    String? id,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? familyMemberId,
  }) {
    return Expense(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      familyMemberId: familyMemberId ?? this.familyMemberId,
    );
  }
}
