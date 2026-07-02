import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    super.id,
    required super.name,
    required super.username,
    required super.pin,
    required super.role,
    super.isActive = true,
    super.isFirstLogin = true,
    required super.createdAt,
  });

  /// Creates a [UserModel] from a database Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      username: map['username'] as String,
      pin: map['pin'] as String,
      role: UserRole.fromString(map['role'] as String? ?? 'Cashier'),
      isActive: (map['is_active'] as int? ?? 1) == 1,
      isFirstLogin: (map['is_first_login'] as int? ?? 1) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Converts this model to a database Map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'username': username,
      'pin': pin,
      'role': role.value,
      'is_active': isActive ? 1 : 0,
      'is_first_login': isFirstLogin ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Converts a domain [User] entity to a [UserModel].
  factory UserModel.fromEntity(User entity) {
    return UserModel(
      id: entity.id,
      name: entity.name,
      username: entity.username,
      pin: entity.pin,
      role: entity.role,
      isActive: entity.isActive,
      isFirstLogin: entity.isFirstLogin,
      createdAt: entity.createdAt,
    );
  }

  /// Converts this model back to a domain [User] entity.
  User toEntity() {
    return User(
      id: id,
      name: name,
      username: username,
      pin: pin,
      role: role,
      isActive: isActive,
      isFirstLogin: isFirstLogin,
      createdAt: createdAt,
    );
  }
}
