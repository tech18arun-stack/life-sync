/// AIInsight model for MongoDB
class AIInsight {
  final String id;
  final String title;
  final String content;
  final String type; // 'tip', 'warning', 'recommendation', 'insight'
  final String category; // 'budget', 'savings', 'spending', 'general'
  final DateTime createdAt;
  final String? icon;
  final int priority; // 1-5, higher is more important

  AIInsight({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    required this.category,
    required this.createdAt,
    this.icon,
    this.priority = 3,
  });

  factory AIInsight.fromJson(Map<String, dynamic> json) {
    return AIInsight(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'insight',
      category: json['category'] ?? 'general',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      icon: json['icon'],
      priority: json['priority'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      if (icon != null) 'icon': icon,
      'priority': priority,
    };
  }
}
