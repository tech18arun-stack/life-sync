/// Budget model for MongoDB
class Budget {
  String? id;
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
      id: json['_id'] ?? json['id'],
      category: json['category'] ?? 'Other',
      allocatedAmount: (json['allocatedAmount'] ?? json['amount'] ?? 0)
          .toDouble(),
      spentAmount: (json['spentAmount'] ?? 0).toDouble(),
      month: json['month'] ?? DateTime.now().month,
      year: json['year'] ?? DateTime.now().year,
      isActive: json['isActive'] ?? true,
      alertThreshold: (json['alertThreshold'] ?? 80).toDouble(),
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
      'category': category,
      'allocatedAmount': allocatedAmount,
      'spentAmount': spentAmount,
      'month': month,
      'year': year,
      'isActive': isActive,
      'alertThreshold': alertThreshold,
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
