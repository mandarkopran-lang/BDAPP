import 'package:cloud_firestore/cloud_firestore.dart';

enum BreakdownStatus { open, assigned, inProgress, resolved, closed }

BreakdownStatus breakdownStatusFromString(String value) {
  switch (value) {
    case 'assigned':
      return BreakdownStatus.assigned;
    case 'inProgress':
      return BreakdownStatus.inProgress;
    case 'resolved':
      return BreakdownStatus.resolved;
    case 'closed':
      return BreakdownStatus.closed;
    default:
      return BreakdownStatus.open;
  }
}

String breakdownStatusToString(BreakdownStatus status) => status.name;

enum BreakdownPriority { low, medium, high, critical }

BreakdownPriority breakdownPriorityFromString(String value) {
  switch (value) {
    case 'medium':
      return BreakdownPriority.medium;
    case 'high':
      return BreakdownPriority.high;
    case 'critical':
      return BreakdownPriority.critical;
    default:
      return BreakdownPriority.low;
  }
}

String breakdownPriorityToString(BreakdownPriority p) => p.name;

class BreakdownModel {
  final String id;
  final String companyId;
  final String plantId;
  final String? departmentId;
  final String title;
  final String description;
  final BreakdownStatus status;
  final BreakdownPriority priority;
  final String reportedBy; // uid
  final String? assignedTo; // uid
  final List<String> imageUrls;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final List<Map<String, dynamic>> statusHistory; // {status, by, at, note}

  BreakdownModel({
    required this.id,
    required this.companyId,
    required this.plantId,
    this.departmentId,
    required this.title,
    required this.description,
    this.status = BreakdownStatus.open,
    this.priority = BreakdownPriority.medium,
    required this.reportedBy,
    this.assignedTo,
    this.imageUrls = const [],
    required this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.statusHistory = const [],
  });

  factory BreakdownModel.fromMap(Map<String, dynamic> map, String id) {
    return BreakdownModel(
      id: id,
      companyId: map['companyId'] ?? '',
      plantId: map['plantId'] ?? '',
      departmentId: map['departmentId'],
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: breakdownStatusFromString(map['status'] ?? 'open'),
      priority: breakdownPriorityFromString(map['priority'] ?? 'medium'),
      reportedBy: map['reportedBy'] ?? '',
      assignedTo: map['assignedTo'],
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(map['imageUrls'])
          : [],
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      resolvedAt: (map['resolvedAt'] is Timestamp)
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
      statusHistory: map['statusHistory'] != null
          ? List<Map<String, dynamic>>.from(
              (map['statusHistory'] as List)
                  .map((e) => Map<String, dynamic>.from(e)))
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'plantId': plantId,
      'departmentId': departmentId,
      'title': title,
      'description': description,
      'status': breakdownStatusToString(status),
      'priority': breakdownPriorityToString(priority),
      'reportedBy': reportedBy,
      'assignedTo': assignedTo,
      'imageUrls': imageUrls,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'statusHistory': statusHistory,
    };
  }
}
