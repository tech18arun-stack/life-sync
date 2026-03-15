/// FamilyMember model for Supabase
class FamilyMember {
  String? id;
  String? userId;
  String name;
  String? relation;
  DateTime? dateOfBirth;
  String? bloodGroup;
  String? phone;
  String? email;
  String? avatarColor;
  bool isEmergencyContact;
  DateTime? createdAt;
  DateTime? updatedAt;

  FamilyMember({
    this.id,
    this.userId,
    required this.name,
    this.relation,
    this.dateOfBirth,
    this.bloodGroup,
    this.phone,
    this.email,
    this.avatarColor,
    this.isEmergencyContact = false,
    this.createdAt,
    this.updatedAt,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['_id'] ?? json['id'],
      userId: json['user_id'] ?? json['userId'],
      name: json['name'] ?? '',
      relation: json['relationship'] ?? json['relation'],
      dateOfBirth: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'])
          : (json['dateOfBirth'] != null
                ? DateTime.parse(json['dateOfBirth'])
                : null),
      bloodGroup: json['bloodGroup'],
      phone: json['phone_number'] ?? json['phone'],
      email: json['email'],
      avatarColor: json['avatarColor'] ?? '#6C63FF',
      isEmergencyContact: json['isEmergencyContact'] ?? false,
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
      if (relation != null) 'relationship': relation, // Fixed key
      if (dateOfBirth != null)
        'birth_date': dateOfBirth!.toIso8601String(), // Fixed key
      if (phone != null) 'phone_number': phone, // Fixed key
      if (email != null) 'email': email,
      // Removed bloodGroup, avatarColor, isEmergencyContact (not in schema)
    };
  }

  FamilyMember copyWith({
    String? id,
    String? userId,
    String? name,
    String? relation,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? phone,
    String? email,
    String? avatarColor,
    bool? isEmergencyContact,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      avatarColor: avatarColor ?? this.avatarColor,
      isEmergencyContact: isEmergencyContact ?? this.isEmergencyContact,
    );
  }
}
