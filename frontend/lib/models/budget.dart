/// Budget model for Supabase
class Budget {
  String? id;
  String? userId;
  String category;
  double allocatedAmount;
  double spentAmount;
  int month;
  int year;
  bool isActive;
  double alertThreshold;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Computed properties for compatibility
  DateTime get startDate => DateTime(year, month, 1);
  DateTime get endDate => DateTime(year, month + 1, 0);
  String get period => '${_monthName(month)} $year';
  bool get alertEnabled => alertThreshold > 0;

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[(month - 1) % 12];
  }

  Budget({
    this.id,
    this.userId,
    required this.category,
    required this.allocatedAmount,
    this.spentAmount = 0,
    required this.month,
    required this.year,
    this.isActive = true,
    this.alertThreshold = 80,
    this.createdAt,
    this.updatedAt,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      userId: json['user_id'],
      category: json['category'] ?? 'Other',
      allocatedAmount: (json['allocated_amount'] ?? json['amount'] ?? 0)
          .toDouble(),
      spentAmount: (json['spent_amount'] ?? 0).toDouble(),
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      isActive: json['is_active'] ?? true,
      alertThreshold: (json['alert_threshold'] ?? 80).toDouble(),
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
      'category': category,
      'allocated_amount': allocatedAmount,
      'spent_amount': spentAmount,
      'month': month,
      'year': year,
      'is_active': isActive,
      'alert_threshold': alertThreshold,
    };
  }

  // Computed properties
  double get percentageUsed =>
      allocatedAmount > 0 ? (spentAmount / allocatedAmount) * 100 : 0;
  bool get isOverBudget => spentAmount > allocatedAmount;
  bool get shouldAlert => percentageUsed >= alertThreshold && !isOverBudget;
  double get remainingAmount => allocatedAmount - spentAmount;

  Budget copyWith({
    String? id,
    String? userId,
    String? category,
    double? allocatedAmount,
    double? spentAmount,
    int? month,
    int? year,
    bool? isActive,
    double? alertThreshold,
  }) {
    return Budget(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      category: category ?? this.category,
      allocatedAmount: allocatedAmount ?? this.allocatedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      month: month ?? this.month,
      year: year ?? this.year,
      isActive: isActive ?? this.isActive,
      alertThreshold: alertThreshold ?? this.alertThreshold,
    );
  }
}
