/// FamilyMember model for MongoDB
class FamilyMember {
  String? id;
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
      name: json['name'] ?? '',
      relation: json['relation'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      bloodGroup: json['bloodGroup'],
      phone: json['phone'],
      email: json['email'],
      avatarColor: json['avatarColor'] ?? '#6C63FF',
      isEmergencyContact: json['isEmergencyContact'] ?? false,
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
      if (relation != null) 'relation': relation,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (bloodGroup != null) 'bloodGroup': bloodGroup,
      if (phone != null) 'phone': phone,
      if (email != null) 'email': email,
      if (avatarColor != null) 'avatarColor': avatarColor,
      'isEmergencyContact': isEmergencyContact,
    };
  }

  FamilyMember copyWith({
    String? id,
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
