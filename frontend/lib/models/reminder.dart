/// Reminder model
class Reminder {
  String? id;
  String title;
  String type; // emi, loan, recharge, bill, custom
  DateTime dueDate;
  double? amount;
  String? description;
  bool isRecurring;
  String? recurringType; // monthly, weekly, yearly
  bool notificationEnabled;
  int? notificationDaysBefore;
  bool isPaid;
  DateTime? paidDate;
  String? linkedExpenseId;

  Reminder({
    this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.amount,
    this.description,
    this.isRecurring = false,
    this.recurringType,
    this.notificationEnabled = true,
    this.notificationDaysBefore = 3,
    this.isPaid = false,
    this.paidDate,
    this.linkedExpenseId,
  });

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
  bool get isDueSoon =>
      !isPaid &&
      dueDate.isAfter(DateTime.now()) &&
      dueDate.isBefore(DateTime.now().add(const Duration(days: 7)));

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'type': type,
      'dueDate': dueDate.toIso8601String(),
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      'isRecurring': isRecurring,
      if (recurringType != null) 'recurringType': recurringType,
      'notificationEnabled': notificationEnabled,
      if (notificationDaysBefore != null)
        'notificationDaysBefore': notificationDaysBefore,
      'isPaid': isPaid,
      if (paidDate != null) 'paidDate': paidDate!.toIso8601String(),
      if (linkedExpenseId != null) 'linkedExpenseId': linkedExpenseId,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      type: json['type'] ?? 'custom',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      amount: json['amount']?.toDouble(),
      description: json['description'],
      isRecurring: json['isRecurring'] ?? false,
      recurringType: json['recurringType'],
      notificationEnabled: json['notificationEnabled'] ?? true,
      notificationDaysBefore: json['notificationDaysBefore'] ?? 3,
      isPaid: json['isPaid'] ?? false,
      paidDate: json['paidDate'] != null
          ? DateTime.parse(json['paidDate'])
          : null,
      linkedExpenseId: json['linkedExpenseId'],
    );
  }

  Reminder copyWith({
    String? id,
    String? title,
    String? type,
    DateTime? dueDate,
    double? amount,
    String? description,
    bool? isRecurring,
    String? recurringType,
    bool? notificationEnabled,
    int? notificationDaysBefore,
    bool? isPaid,
    DateTime? paidDate,
    String? linkedExpenseId,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationDaysBefore:
          notificationDaysBefore ?? this.notificationDaysBefore,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      linkedExpenseId: linkedExpenseId ?? this.linkedExpenseId,
    );
  }
}
