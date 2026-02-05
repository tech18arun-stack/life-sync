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
  // User type: 'admin' (registered via Register Screen) or 'client' (created by admin)
  String userType;
  // Family hierarchy fields
  String role; // 'owner' or 'member' within family
  String? parentUserId; // The admin who created this client user
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
    this.userType = 'admin', // Default to admin for register screen
    this.role = 'owner',
    this.parentUserId,
    this.familyId,
    this.relation,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      avatar: json['avatar'],
      isActive: json['is_active'] ?? json['isActive'] ?? true,
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : (json['lastLogin'] != null
                ? DateTime.parse(json['lastLogin'])
                : null),
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
      userType: json['user_type'] ?? json['userType'] ?? 'admin',
      role: json['role'] ?? 'owner',
      parentUserId: json['parent_user_id'] ?? json['parentUserId'],
      familyId: json['family_id'] ?? json['familyId'],
      relation: json['relation'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'email': email,
      if (phone != null) 'phone': phone,
      if (avatar != null) 'avatar': avatar,
      'is_active': isActive,
      'user_type': userType,
      'role': role,
      if (parentUserId != null) 'parent_user_id': parentUserId,
      if (familyId != null) 'family_id': familyId,
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
    String? userType,
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
      userType: userType ?? this.userType,
      role: role ?? this.role,
      parentUserId: parentUserId ?? this.parentUserId,
      familyId: familyId ?? this.familyId,
      relation: relation ?? this.relation,
    );
  }

  // User type checks
  bool get isAdmin => userType == 'admin';
  bool get isClient => userType == 'client';

  // Role checks (within family)
  bool get isOwner => role == 'owner';
  bool get isMember => role == 'member';
}
