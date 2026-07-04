import 'package:cloud_firestore/cloud_firestore.dart';

class PlantModel {
  final String id;
  final String companyId;
  final String name;
  final String? location;
  final String? departmentId;
  final DateTime createdAt;

  PlantModel({
    required this.id,
    required this.companyId,
    required this.name,
    this.location,
    this.departmentId,
    required this.createdAt,
  });

  factory PlantModel.fromMap(Map<String, dynamic> map, String id) {
    return PlantModel(
      id: id,
      companyId: map['companyId'] ?? '',
      name: map['name'] ?? '',
      location: map['location'],
      departmentId: map['departmentId'],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'name': name,
      'location': location,
      'departmentId': departmentId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
