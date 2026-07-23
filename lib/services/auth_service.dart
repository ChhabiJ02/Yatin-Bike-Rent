import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
  static const _validRoles = {'Admin', 'Staff', 'Customer'};
  static const Map<String, String> _emailAliases = {
    'admin': 'admin@gmail.com',
    'staff': 'staff@gmail.com',
    'customer': 'customer@gmail.com',
  };

  static User? get currentUser => _auth.currentUser;
  static const Duration sessionDuration = Duration(hours: 2);

  static Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred;
  }

  static Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final resolvedEmail = resolveLoginEmail(email);
    final cred = await _auth.signInWithEmailAndPassword(
      email: resolvedEmail,
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid != null) {
      await _writeLastLogin(uid);
    }
    return cred;
  }

  static Future<void> _writeLastLogin(String uid) async {
    try {
      await _db.collection('users').doc(uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  static Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  static Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> saveUserProfile({
    required String uid,
    required String name,
    required String role,
    String? email,
  }) async {
    await _db.collection('users').doc(uid).set({
      'name': name,
      'role': role,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['role'] as String?;
  }

  static Future<String?> resolveUserRole({
    required String uid,
    String? email,
    String? loginIdentifier,
  }) async {
    final roleByUid = await _roleFromUserDocument(uid);
    if (roleByUid != null) return roleByUid;

    for (final candidateEmail in _roleLookupEmails(email, loginIdentifier)) {
      final roleByEmail = await _roleFromUserEmail(candidateEmail);
      if (roleByEmail != null) return roleByEmail;
    }

    final claimedRole = await _roleFromTokenClaims();
    if (_validRoles.contains(claimedRole)) return claimedRole;

    return null;
  }

  static Future<String?> _roleFromUserDocument(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return _normalizeRole(doc.data()?['role']);
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return null;
      rethrow;
    }
  }

  static Future<String?> _roleFromUserEmail(String email) async {
    final emailMatch = await _db
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (emailMatch.docs.isEmpty) return null;
    return _normalizeRole(emailMatch.docs.first.data()['role']);
  }

  static Set<String> _roleLookupEmails(String? email, String? loginIdentifier) {
    return {
      if (email != null && email.trim().isNotEmpty) email.trim(),
      if (email != null && email.trim().isNotEmpty) email.trim().toLowerCase(),
      if (loginIdentifier != null && loginIdentifier.trim().isNotEmpty)
        resolveLoginEmail(loginIdentifier),
    };
  }

  static String? _normalizeRole(Object? role) {
    final value = role is String ? role.trim() : null;
    if (value == null || value.isEmpty) return null;
    for (final validRole in _validRoles) {
      if (validRole.toLowerCase() == value.toLowerCase()) {
        return validRole;
      }
    }
    return null;
  }

  static Future<String?> _roleFromTokenClaims() async {
    try {
      final token = await currentUser?.getIdTokenResult();
      return token?.claims?['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  static String resolveLoginEmail(String identifier) {
    final normalized = identifier.trim().toLowerCase();
    return _emailAliases[normalized] ?? normalized;
  }

  static Future<void> ensureUserProfile({
    required String uid,
    required String email,
    String role = 'Customer',
  }) async {
    try {
      await _db.collection('users').doc(uid).set({
        'email': email,
        'role': role,
        'name': email.split('@').first,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      if (e.code != 'permission-denied') rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>>
  currentUserProfileStream() {
    final uid = currentUser?.uid;
    if (uid == null) {
      return const Stream.empty();
    }
    return _db.collection('users').doc(uid).snapshots();
  }

  static bool isCurrentSessionActive() {
    final signedInAt = currentUser?.metadata.lastSignInTime;
    if (signedInAt == null) return false;
    return DateTime.now().difference(signedInAt) < sessionDuration;
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() {
    return _db.collection('users').snapshots();
  }

  static Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).update({
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
