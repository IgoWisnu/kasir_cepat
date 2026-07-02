import 'package:equatable/equatable.dart';

enum UserRole {
  owner,
  staff;

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
      case 'owner':
        return UserRole.owner;
      case 'cashier':
      case 'staff':
      default:
        return UserRole.staff;
    }
  }

  String get value {
    switch (this) {
      case UserRole.owner:
        return 'Admin';
      case UserRole.staff:
        return 'Cashier';
    }
  }

  bool get isOwner => this == UserRole.owner;
  bool get isStaff => this == UserRole.staff;
}

class User extends Equatable {
  final int? id;
  final String name;
  final String username;
  final String pin;
  final UserRole role;
  final bool isActive;
  final bool isFirstLogin;
  final DateTime createdAt;

  const User({
    this.id,
    required this.name,
    required this.username,
    required this.pin,
    required this.role,
    this.isActive = true,
    this.isFirstLogin = true,
    required this.createdAt,
  });

  User copyWith({
    int? id,
    String? name,
    String? username,
    String? pin,
    UserRole? role,
    bool? isActive,
    bool? isFirstLogin,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      username: username ?? this.username,
      pin: pin ?? this.pin,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        username,
        pin,
        role,
        isActive,
        isFirstLogin,
        createdAt,
      ];
}
