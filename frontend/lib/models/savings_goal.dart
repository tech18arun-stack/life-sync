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
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? json['title'] ?? '',
      targetAmount: (json['targetAmount'] ?? 0).toDouble(),
      currentAmount: (json['currentAmount'] ?? 0).toDouble(),
      targetDate: json['targetDate'] != null
          ? DateTime.parse(json['targetDate'])
          : null,
      category: json['category'] ?? 'Other',
      priority: json['priority'] ?? 'Medium',
      isCompleted: json['isCompleted'] ?? false,
      notes: json['notes'] ?? json['description'],
      color: json['color'] ?? '#6C63FF',
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
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      if (targetDate != null) 'targetDate': targetDate!.toIso8601String(),
      'category': category,
      'priority': priority,
      'isCompleted': isCompleted,
      if (notes != null) 'notes': notes,
      if (color != null) 'color': color,
    };
  }

  // Computed properties
  double get progress =>
      targetAmount > 0 ? (currentAmount / targetAmount) * 100 : 0;
  double get remainingAmount => targetAmount - currentAmount;

  SavingsGoal copyWith({
    String? id,
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
