/// FamilyNumber model for Supabase - dedicated for phone contacts
class FamilyNumber {
  String? id;
  String? userId;
  String name;
  String phone;
  String? relation;
  String category;
  bool isEmergency;
  bool isPrimary;
  String? notes;
  String? avatarColor;
  DateTime? createdAt;
  DateTime? updatedAt;

  FamilyNumber({
    this.id,
    this.userId,
    required this.name,
    required this.phone,
    this.relation,
    this.category = 'Family',
    this.isEmergency = false,
    this.isPrimary = false,
    this.notes,
    this.avatarColor,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyNumber.fromJson(Map<String, dynamic> json) {
    return FamilyNumber(
      id: json['_id'] ?? json['id'],
      userId: json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      phone: json['phone_number'] ?? json['phone'] ?? '', // Fixed key
      relation: json['relation'],
      category: json['category'] ?? 'Family',
      isEmergency:
          json['is_emergency'] ?? json['isEmergency'] ?? false, // Fixed key
      isPrimary: json['is_primary'] ?? json['isPrimary'] ?? false, // Fixed key
      notes: json['notes'],
      avatarColor: json['avatarColor'] ?? '#6C63FF',
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
      if (id != null) '_id': id,
      if (userId != null) 'user_id': userId,
      'name': name,
      'phone_number': phone, // Fixed key
      'category': category,
      'is_emergency': isEmergency, // Fixed key
      'is_primary': isPrimary, // Fixed key
      if (notes != null) 'notes': notes,
      // Removed relation, avatarColor (not in schema)
    };
  }

  FamilyNumber copyWith({
    String? id,
    String? userId,
    String? name,
    String? phone,
    String? relation,
    String? category,
    bool? isEmergency,
    bool? isPrimary,
    String? notes,
    String? avatarColor,
  }) {
    return FamilyNumber(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relation: relation ?? this.relation,
      category: category ?? this.category,
      isEmergency: isEmergency ?? this.isEmergency,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
