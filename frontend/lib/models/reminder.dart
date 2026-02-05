/// Reminder model
class Reminder {
  String? id;
  String? userId;
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
  String? contactName;
  String? phoneNumber;
  String? notes;

  Reminder({
    this.id,
    this.userId,
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
    this.contactName,
    this.phoneNumber,
    this.notes,
  });

  bool get isOverdue => !isPaid && dueDate.isBefore(DateTime.now());
  bool get isDueSoon =>
      !isPaid &&
      dueDate.isAfter(DateTime.now()) &&
      dueDate.isBefore(DateTime.now().add(const Duration(days: 7)));

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': title,
      'type': type,
      'due_date': dueDate.toIso8601String(),
      if (amount != null) 'amount': amount,
      if (description != null) 'description': description,
      if (recurringType != null) 'repeat_interval': recurringType,
      'is_paid': isPaid,
      if (notes != null) 'notes': notes,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] ?? json['_id'],
      userId: json['user_id'] ?? json['userId'],
      title: json['title'] ?? '',
      type: json['type'] ?? 'custom',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : (json['dueDate'] != null
                ? DateTime.parse(json['dueDate'])
                : DateTime.now()),
      amount: json['amount']?.toDouble(),
      description: json['description'],
      isRecurring:
          json['repeat_interval'] != null || json['isRecurring'] == true,
      recurringType: json['repeat_interval'] ?? json['recurringType'],
      notificationEnabled: json['notificationEnabled'] ?? true,
      notificationDaysBefore: json['notificationDaysBefore'] ?? 3,
      isPaid: json['is_paid'] ?? json['isPaid'] ?? false,
      paidDate: json['paid_date'] != null
          ? DateTime.parse(json['paid_date'])
          : (json['paidDate'] != null
                ? DateTime.parse(json['paidDate'])
                : null),
      linkedExpenseId: json['linked_expense_id'] ?? json['linkedExpenseId'],
      contactName: json['contact_name'] ?? json['contactName'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      notes: json['notes'],
    );
  }

  Reminder copyWith({
    String? id,
    String? userId,
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
    String? contactName,
    String? phoneNumber,
    String? notes,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
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
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      notes: notes ?? this.notes,
    );
  }
}
