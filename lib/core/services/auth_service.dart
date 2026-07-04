import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles all Firebase Phone Authentication (OTP) logic.
///
/// IMPORTANT (common OTP issues & fixes):
/// 1. "OTP not working / not received":
///    - Make sure SHA-1 & SHA-256 fingerprints are added in Firebase Console
///      (Project Settings > Your App > Add fingerprint) for BOTH debug and
///      release keystores. Missing SHA-1 is the #1 cause of silent OTP failure
///      on Android because Play Integrity / SafetyNet check fails.
///    - Enable "Phone" sign-in provider in Firebase Console > Authentication.
///    - For testing, add test phone numbers in
///      Authentication > Sign-in method > Phone numbers for testing to bypass
///      real SMS (avoids quota limits during development).
///    - google-services.json MUST be regenerated/downloaded after adding SHA-1.
/// 2. "PERMISSION_DENIED" after login:
///    - Usually caused by Firestore rules expecting a `users/{uid}` doc that
///      does not exist yet right after signup. We create it immediately after
///      successful OTP verification (see verifyOtpAndSignIn below) BEFORE any
///      other Firestore read/write happens.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _verificationId;
  int? _resendToken;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Step 1: Send OTP to the given phone number.
  /// [phoneNumber] must be in E.164 format e.g. +919876543210
  Future<void> sendOtp({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(FirebaseAuthException e) onError,
    required Function(PhoneAuthCredential credential) onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-retrieval on Android (SMS auto-read). Sign in directly.
        onAutoVerified(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        // Common causes: invalid phone format, missing SHA-1, quota exceeded,
        // app not verified (Play Integrity), billing not enabled for high volume.
        onError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  /// Step 2: Verify the OTP entered by user and sign in.
  /// Also ensures a corresponding `users/{uid}` Firestore document exists,
  /// which prevents "permission-denied" errors on subsequent reads because
  /// most security rules key off the existence of this document.
  Future<UserCredential> verifyOtpAndSignIn({
    required String smsCode,
    String? verificationId,
  }) async {
    final vId = verificationId ?? _verificationId;
    if (vId == null) {
      throw FirebaseAuthException(
        code: 'missing-verification-id',
        message: 'No verification in progress. Please request a new OTP.',
      );
    }
    final credential =
        PhoneAuthProvider.credential(verificationId: vId, smsCode: smsCode);

    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(userCredential.user!);
    return userCredential;
  }

  Future<UserCredential> signInWithCredential(
      PhoneAuthCredential credential) async {
    final userCredential = await _auth.signInWithCredential(credential);
    await _ensureUserDocument(userCredential.user!);
    return userCredential;
  }

  /// Creates a minimal `users/{uid}` doc on first login if it doesn't exist.
  /// New users default to role=user and companyId=null (unassigned) until
  /// an Admin assigns them to a company. This avoids "undefined field" and
  /// "permission-denied" errors because every authenticated user always has
  /// a matching Firestore profile immediately after auth.
  Future<void> _ensureUserDocument(User firebaseUser) async {
    final docRef = _firestore.collection('users').doc(firebaseUser.uid);
    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      final newUser = UserModel(
        uid: firebaseUser.uid,
        phoneNumber: firebaseUser.phoneNumber ?? '',
        name: 'New User',
        role: UserRole.user,
        companyId: null,
        createdAt: DateTime.now(),
      );
      await docRef.set(newUser.toMap());
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
