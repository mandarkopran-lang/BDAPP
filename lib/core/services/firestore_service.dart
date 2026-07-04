import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/company_model.dart';
import '../models/department_model.dart';
import '../models/plant_model.dart';
import '../models/breakdown_model.dart';

/// Central data-access layer. ALL reads/writes are scoped by companyId
/// to enforce multi-tenant isolation at the application layer, in addition
/// to Firestore security rules (defense in depth).
///
/// Firestore structure:
/// users/{uid}                                  -> profile + role + companyId
/// companies/{companyId}                        -> company info
/// companies/{companyId}/departments/{deptId}
/// companies/{companyId}/plants/{plantId}
/// companies/{companyId}/breakdowns/{breakdownId}
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- USERS ----------------

  Future<UserModel?> getUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, doc.id);
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  /// Admin: list all users belonging to a company.
  Stream<List<UserModel>> streamCompanyUsers(String companyId) {
    return _db
        .collection('users')
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromMap(d.data(), d.id)).toList());
  }

  /// Admin: assign a role + company to a user (by phone lookup or uid).
  Future<void> assignUserToCompany({
    required String uid,
    required String companyId,
    required UserRole role,
    String? departmentId,
    String? plantId,
  }) async {
    await _db.collection('users').doc(uid).update({
      'companyId': companyId,
      'role': userRoleToString(role),
      'departmentId': departmentId,
      'plantId': plantId,
    });
  }

  Future<UserModel?> findUserByPhone(String phoneNumber) async {
    final snap = await _db
        .collection('users')
        .where('phoneNumber', isEqualTo: phoneNumber)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return UserModel.fromMap(snap.docs.first.data(), snap.docs.first.id);
  }

  // ---------------- COMPANIES ----------------

  Future<String> createCompany(CompanyModel company) async {
    final ref = await _db.collection('companies').add(company.toMap());
    return ref.id;
  }

  Stream<List<CompanyModel>> streamAllCompanies() {
    return _db
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CompanyModel.fromMap(d.data(), d.id)).toList());
  }

  Future<CompanyModel?> getCompany(String companyId) async {
    final doc = await _db.collection('companies').doc(companyId).get();
    if (!doc.exists) return null;
    return CompanyModel.fromMap(doc.data()!, doc.id);
  }

  // ---------------- DEPARTMENTS ----------------

  CollectionReference<Map<String, dynamic>> _departmentsRef(String companyId) =>
      _db.collection('companies').doc(companyId).collection('departments');

  Future<String> createDepartment(DepartmentModel dept) async {
    final ref = await _departmentsRef(dept.companyId).add(dept.toMap());
    return ref.id;
  }

  Stream<List<DepartmentModel>> streamDepartments(String companyId) {
    return _departmentsRef(companyId).orderBy('createdAt').snapshots().map(
        (snap) => snap.docs
            .map((d) => DepartmentModel.fromMap(d.data(), d.id))
            .toList());
  }

  Future<void> deleteDepartment(String companyId, String deptId) async {
    await _departmentsRef(companyId).doc(deptId).delete();
  }

  // ---------------- PLANTS ----------------

  CollectionReference<Map<String, dynamic>> _plantsRef(String companyId) =>
      _db.collection('companies').doc(companyId).collection('plants');

  Future<String> createPlant(PlantModel plant) async {
    final ref = await _plantsRef(plant.companyId).add(plant.toMap());
    return ref.id;
  }

  Stream<List<PlantModel>> streamPlants(String companyId) {
    return _plantsRef(companyId).orderBy('createdAt').snapshots().map((snap) =>
        snap.docs.map((d) => PlantModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> deletePlant(String companyId, String plantId) async {
    await _plantsRef(companyId).doc(plantId).delete();
  }

  // ---------------- BREAKDOWNS ----------------

  CollectionReference<Map<String, dynamic>> _breakdownsRef(String companyId) =>
      _db.collection('companies').doc(companyId).collection('breakdowns');

  Future<String> createBreakdown(BreakdownModel breakdown) async {
    final ref = await _breakdownsRef(breakdown.companyId).add({
      ...breakdown.toMap(),
      'statusHistory': [
        {
          'status': 'open',
          'by': breakdown.reportedBy,
          'at': Timestamp.now(),
          'note': 'Breakdown reported',
        }
      ],
    });
    return ref.id;
  }

  Stream<List<BreakdownModel>> streamBreakdowns(String companyId,
      {String? plantId, String? assignedTo, BreakdownStatus? status}) {
    Query<Map<String, dynamic>> query = _breakdownsRef(companyId);
    if (plantId != null) {
      query = query.where('plantId', isEqualTo: plantId);
    }
    if (assignedTo != null) {
      query = query.where('assignedTo', isEqualTo: assignedTo);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: breakdownStatusToString(status));
    }
    query = query.orderBy('createdAt', descending: true);
    return query.snapshots().map((snap) =>
        snap.docs.map((d) => BreakdownModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<BreakdownModel?> streamBreakdown(String companyId, String id) {
    return _breakdownsRef(companyId).doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BreakdownModel.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> assignBreakdown({
    required String companyId,
    required String breakdownId,
    required String assignedTo,
    required String assignedBy,
  }) async {
    await _breakdownsRef(companyId).doc(breakdownId).update({
      'assignedTo': assignedTo,
      'status': breakdownStatusToString(BreakdownStatus.assigned),
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': 'assigned',
          'by': assignedBy,
          'at': Timestamp.now(),
          'note': 'Assigned to technician',
        }
      ]),
    });
  }

  Future<void> updateBreakdownStatus({
    required String companyId,
    required String breakdownId,
    required BreakdownStatus status,
    required String updatedBy,
    String? note,
  }) async {
    final data = <String, dynamic>{
      'status': breakdownStatusToString(status),
      'updatedAt': Timestamp.now(),
      'statusHistory': FieldValue.arrayUnion([
        {
          'status': breakdownStatusToString(status),
          'by': updatedBy,
          'at': Timestamp.now(),
          'note': note ?? '',
        }
      ]),
    };
    if (status == BreakdownStatus.resolved || status == BreakdownStatus.closed) {
      data['resolvedAt'] = Timestamp.now();
    }
    await _breakdownsRef(companyId).doc(breakdownId).update(data);
  }

  Future<void> addBreakdownImages({
    required String companyId,
    required String breakdownId,
    required List<String> imageUrls,
  }) async {
    await _breakdownsRef(companyId).doc(breakdownId).update({
      'imageUrls': FieldValue.arrayUnion(imageUrls),
      'updatedAt': Timestamp.now(),
    });
  }
}
