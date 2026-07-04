import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'auth_service.dart';
import 'firestore_service.dart';

enum AuthStatus { unknown, unauthenticated, authenticated }

/// App-wide auth + current-user-profile state.
/// Listens to FirebaseAuth changes and keeps the Firestore user profile
/// (role, companyId, etc.) in sync so the whole UI can react to role
/// changes made by an Admin in real time.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUserProfile;
  User? firebaseUser;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<UserModel?>? _profileSub;

  AuthProvider() {
    _authSub = _authService.authStateChanges.listen(_onAuthChanged);
  }

  AuthService get authService => _authService;

  void _onAuthChanged(User? user) {
    firebaseUser = user;
    _profileSub?.cancel();
    if (user == null) {
      status = AuthStatus.unauthenticated;
      currentUserProfile = null;
      notifyListeners();
      return;
    }
    _profileSub = _firestoreService.streamUser(user.uid).listen((profile) {
      currentUserProfile = profile;
      status = AuthStatus.authenticated;
      notifyListeners();
    });
  }

  bool get isAdmin => currentUserProfile?.role == UserRole.admin;
  bool get isManager => currentUserProfile?.role == UserRole.manager;
  bool get isSupervisor => currentUserProfile?.role == UserRole.supervisor;
  bool get hasCompany => currentUserProfile?.companyId != null;

  Future<void> signOut() async {
    await _authService.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }
}
