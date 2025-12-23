/// FamilyNumber model for MongoDB - dedicated for phone contacts
class FamilyNumber {
  String? id;
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
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      relation: json['relation'],
      category: json['category'] ?? 'Family',
      isEmergency: json['isEmergency'] ?? false,
      isPrimary: json['isPrimary'] ?? false,
      notes: json['notes'],
      avatarColor: json['avatarColor'] ?? '#6C63FF',
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
      'phone': phone,
      if (relation != null) 'relation': relation,
      'category': category,
      'isEmergency': isEmergency,
      'isPrimary': isPrimary,
      if (notes != null) 'notes': notes,
      if (avatarColor != null) 'avatarColor': avatarColor,
    };
  }

  FamilyNumber copyWith({
    String? id,
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
