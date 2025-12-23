/// User model for authentication
class User {
  String? id;
  String name;
  String email;
  String? phone;
  String? avatar;
  bool isActive;
  DateTime? lastLogin;
  DateTime? createdAt;
  DateTime? updatedAt;
  // Family hierarchy fields
  String role; // 'owner' or 'member'
  String? parentUserId;
  String? familyId;
  String? relation;

  User({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    this.isActive = true,
    this.lastLogin,
    this.createdAt,
    this.updatedAt,
    this.role = 'owner',
    this.parentUserId,
    this.familyId,
    this.relation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null
          ? DateTime.parse(json['lastLogin'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      role: json['role'] ?? 'owner',
      parentUserId: json['parentUserId'],
      familyId: json['familyId'],
      relation: json['relation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      'isActive': isActive,
      'role': role,
      if (parentUserId != null) 'parentUserId': parentUserId,
      if (familyId != null) 'familyId': familyId,
      if (relation != null) 'relation': relation,
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? avatar,
    bool? isActive,
    String? role,
    String? parentUserId,
    String? familyId,
    String? relation,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatar: avatar ?? this.avatar,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin,
      createdAt: createdAt,
      updatedAt: updatedAt,
      role: role ?? this.role,
      parentUserId: parentUserId ?? this.parentUserId,
      familyId: familyId ?? this.familyId,
      relation: relation ?? this.relation,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isMember => role == 'member';
}
