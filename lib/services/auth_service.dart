import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user?.uid;
    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return cred;
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

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  static Stream<DocumentSnapshot<Map<String, dynamic>>> currentUserProfileStream() {
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
