/// Task model for MongoDB
class Task {
  String? id;
  String title;
  String? description;
  DateTime? dueDate;
  String priority;
  String status;
  bool isCompleted;
  DateTime? completedAt;
  String? assignedTo;
  String category;
  DateTime? createdAt;
  DateTime? updatedAt;

  Task({
    this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.priority = 'Medium',
    this.status = 'Pending',
    this.isCompleted = false,
    this.completedAt,
    this.assignedTo,
    this.category = 'Other',
    this.createdAt,
    this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      isCompleted: json['isCompleted'] ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
      assignedTo: json['assignedTo'] is Map
          ? json['assignedTo']['_id']
          : json['assignedTo'],
      category: json['category'] ?? 'Other',
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
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'dueDate': dueDate!.toIso8601String(),
      'priority': priority,
      'status': status,
      'isCompleted': isCompleted,
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      if (assignedTo != null) 'assignedTo': assignedTo,
      'category': category,
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    String? priority,
    String? status,
    bool? isCompleted,
    DateTime? completedAt,
    String? assignedTo,
    String? category,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      assignedTo: assignedTo ?? this.assignedTo,
      category: category ?? this.category,
    );
  }
}
