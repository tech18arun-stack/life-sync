/// FamilyEvent model
class FamilyEvent {
  String? id;
  String title;
  DateTime startDate;
  DateTime? endDate;
  String? description;
  String category; // birthday, anniversary, appointment, celebration, other
  List<String> participants; // family member IDs
  String? location;
  bool isAllDay;
  bool hasReminder;
  int? reminderMinutesBefore;
  String? color;

  FamilyEvent({
    this.id,
    required this.title,
    required this.startDate,
    this.endDate,
    this.description,
    this.category = 'other',
    this.participants = const [],
    this.location,
    this.isAllDay = false,
    this.hasReminder = false,
    this.reminderMinutesBefore,
    this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      if (description != null) 'description': description,
      'category': category,
      'participants': participants,
      if (location != null) 'location': location,
      'isAllDay': isAllDay,
      'hasReminder': hasReminder,
      if (reminderMinutesBefore != null)
        'reminderMinutesBefore': reminderMinutesBefore,
      if (color != null) 'color': color,
    };
  }

  factory FamilyEvent.fromJson(Map<String, dynamic> json) {
    return FamilyEvent(
      id: json['_id'] ?? json['id'],
      title: json['title'] ?? '',
      startDate: json['startDate'] != null
          ? DateTime.parse(json['startDate'])
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      description: json['description'],
      category: json['category'] ?? 'other',
      participants: List<String>.from(json['participants'] ?? []),
      location: json['location'],
      isAllDay: json['isAllDay'] ?? false,
      hasReminder: json['hasReminder'] ?? false,
      reminderMinutesBefore: json['reminderMinutesBefore'],
      color: json['color'],
    );
  }

  FamilyEvent copyWith({
    String? id,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? description,
    String? category,
    List<String>? participants,
    String? location,
    bool? isAllDay,
    bool? hasReminder,
    int? reminderMinutesBefore,
    String? color,
  }) {
    return FamilyEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      description: description ?? this.description,
      category: category ?? this.category,
      participants: participants ?? this.participants,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      color: color ?? this.color,
    );
  }
}
