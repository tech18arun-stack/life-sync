/// Task model for Supabase
class Task {
  String? id;
  String? userId;
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
    this.userId,
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
      id: json['id'] ?? json['_id'],
      userId: json['user_id'] ?? json['userId'],
      title: json['title'] ?? '',
      description: json['description'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : (json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null),
      priority: json['priority'] ?? 'Medium',
      status: json['status'] ?? 'Pending',
      isCompleted: json['is_completed'] ?? json['isCompleted'] ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : (json['completedAt'] != null
                ? DateTime.parse(json['completedAt'])
                : null),
      assignedTo: json['assigned_to'] ?? json['assignedTo'],
      category: json['category'] ?? 'Other',
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
      'title': title,
      if (description != null) 'description': description,
      if (dueDate != null) 'due_date': dueDate!.toIso8601String(),
      'priority': priority,
      'status': status,
      'is_completed': isCompleted,
      if (completedAt != null) 'completed_at': completedAt!.toIso8601String(),
      if (assignedTo != null) 'assigned_to': assignedTo,
      'category': category,
    };
  }

  Task copyWith({
    String? id,
    String? userId,
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
      userId: userId ?? this.userId,
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
