import 'package:cloud_firestore/cloud_firestore.dart';

class DepartmentModel {
  final String id;
  final String companyId;
  final String name;
  final String? description;
  final DateTime createdAt;

  DepartmentModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.description,
    required this.createdAt,
  });

  factory DepartmentModel.fromMap(Map<String, dynamic> map, String id) {
    return DepartmentModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
