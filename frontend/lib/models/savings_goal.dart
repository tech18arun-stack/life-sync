/// SavingsGoal model for MongoDB
class SavingsGoal {
  String? id;
  String name;
  double targetAmount;
  double currentAmount;
  DateTime? targetDate;
  String category;
  String priority;
  bool isCompleted;
  String? notes;
  String? color;
  String? userId;
  DateTime? createdAt;
  DateTime? updatedAt;

  // Backward compatibility getters
  String get title => name;
  String? get description => notes;
  String get emoji => _getCategoryEmoji();
  double get percentageCompleted => progress;
  int get daysRemaining {
    if (targetDate == null) return 0;
    final diff = targetDate!.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  // More backward compatibility
  DateTime get createdDate => createdAt ?? DateTime.now();

  String _getCategoryEmoji() {
    switch (category.toLowerCase()) {
      case 'travel':
        return '✈️';
      case 'education':
        return '📚';
      case 'home':
        return '🏠';
      case 'car':
        return '🚗';
      case 'emergency':
        return '🚨';
      case 'retirement':
        return '👴';
      case 'wedding':
        return '💒';
      case 'health':
        return '🏥';
      default:
        return '💰';
    }
  }

  SavingsGoal({
    this.id,
    this.userId,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.targetDate,
    this.category = 'Other',
    this.priority = 'Medium',
    this.isCompleted = false,
    this.notes,
    this.color,
    this.createdAt,
    this.updatedAt,
  });

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      id: json['id'] ?? json['_id'],
      userId: json['user_id'] ?? json['userId'],
      name: json['title'] ?? json['name'] ?? '',
      targetAmount: (json['target_amount'] ?? json['targetAmount'] ?? 0)
          .toDouble(),
      currentAmount: (json['current_amount'] ?? json['currentAmount'] ?? 0)
          .toDouble(),
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'])
          : (json['targetDate'] != null
                ? DateTime.parse(json['targetDate'])
                : null),
      category: json['category'] ?? 'Other',
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      notes: json['notes'] ?? json['description'],
      color: json['color'] ?? '#6C63FF',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null
                ? DateTime.parse(json['createdAt'])
                : null),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null
                ? DateTime.parse(json['updatedAt'])
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      'title': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      if (targetDate != null) 'target_date': targetDate!.toIso8601String(),
      'category': category,
      'priority': priority,
      'is_completed': isCompleted,
      if (notes != null) 'notes': notes,
    };
  }

  // Computed properties
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  double get remainingAmount => targetAmount - currentAmount;

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? priority,
    bool? isCompleted,
    String? notes,
    String? color,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      color: color ?? this.color,
    );
  }
}
