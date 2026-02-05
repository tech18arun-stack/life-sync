/// Expense model for Supabase
class Expense {
  String? id;
  String? userId;
  String description;
  double amount;
  String category;
  DateTime date;
  String? paymentMethod;
  String? notes;
  String? familyMemberId;
  String? contactName;
  String? phoneNumber;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Backward compatibility getter
  String get title => description;

  Expense({
    this.id,
    this.userId,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    this.paymentMethod,
    this.notes,
    this.familyMemberId,
    this.contactName,
    this.phoneNumber,
    this.createdAt,
    this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      userId: json['user_id'],
      description: json['description'] ?? json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      category: json['category'] ?? 'Other',
      date: json['date'] != null
          ? DateTime.parse(json['date'])
          : DateTime.now(),
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      familyMemberId: json['familyMemberId'],
      contactName: json['contactName'],
      phoneNumber: json['phoneNumber'],
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
      'category': category,
      'date': date.toIso8601String(),
      if (paymentMethod != null) 'payment_method': paymentMethod,
      if (notes != null) 'notes': notes,
      if (familyMemberId != null) 'family_member_id': familyMemberId,
      if (contactName != null) 'contact_name': contactName,
      if (phoneNumber != null) 'phone_number': phoneNumber,
    };
  }

  Expense copyWith({
    String? id,
    String? userId,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? familyMemberId,
    String? contactName,
    String? phoneNumber,
  }) {
    return Expense(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      familyMemberId: familyMemberId ?? this.familyMemberId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}
