import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String? logoUrl;
  final String ownerId; // uid of the admin who owns/created this company
  final bool isActive;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata; // address, GST no, contact, etc.

  CompanyModel({
    required this.id,
    required this.name,
    this.logoUrl,
    required this.ownerId,
    this.isActive = true,
    required this.createdAt,
    this.metadata,
  });

  factory CompanyModel.fromMap(Map<String, dynamic> map, String id) {
    return CompanyModel(
      id: id,
      name: map['name'] ?? '',
      logoUrl: map['logoUrl'],
      ownerId: map['ownerId'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      metadata: map['metadata'] != null
          ? Map<String, dynamic>.from(map['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'logoUrl': logoUrl,
      'ownerId': ownerId,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}
