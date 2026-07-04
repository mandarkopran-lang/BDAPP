import 'package:cloud_firestore/cloud_firestore.dart';

/// Roles supported by the system, ordered by privilege level.
enum UserRole { admin, manager, supervisor, user }

UserRole userRoleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'manager':
      return UserRole.manager;
    case 'supervisor':
      return UserRole.supervisor;
    default:
      return UserRole.user;
  }
}

String userRoleToString(UserRole role) => role.name;

class UserModel {
  final String uid;
  final String phoneNumber;
  final String name;
  final String? email;
  final UserRole role;
  final String? companyId; // null until assigned / for super-admin creating companies
  final String? departmentId;
  final String? plantId;
  final bool isActive;
  final DateTime createdAt;
  final String? fcmToken;

  UserModel({
    required this.uid,
    required this.phoneNumber,
    required this.name,
    this.email,
    required this.role,
    this.companyId,
    this.departmentId,
    this.plantId,
    this.isActive = true,
    required this.createdAt,
    this.fcmToken,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      phoneNumber: map['phoneNumber'] ?? '',
      name: map['name'] ?? '',
      email: map['email'],
      role: userRoleFromString(map['role'] ?? 'user'),
      companyId: map['companyId'],
      departmentId: map['departmentId'],
      plantId: map['plantId'],
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      fcmToken: map['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phoneNumber': phoneNumber,
      'name': name,
      'email': email,
      'role': userRoleToString(role),
      'companyId': companyId,
      'departmentId': departmentId,
      'plantId': plantId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'fcmToken': fcmToken,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    UserRole? role,
    String? companyId,
    String? departmentId,
    String? plantId,
    bool? isActive,
    String? fcmToken,
  }) {
    return UserModel(
      uid: uid,
      phoneNumber: phoneNumber,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      departmentId: departmentId ?? this.departmentId,
      plantId: plantId ?? this.plantId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      fcmToken: fcmToken ?? this.fcmToken,
    );
  }
}
