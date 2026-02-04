import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile.dart';
import 'firestore_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;

  static User? get currentUser => _auth.currentUser;

  static bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<UserCredential?> signIn(String email, String password) async {
    return _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
  }

  static Future<UserCredential?> signUp(String email, String password) async {
    return _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
  }

  /// Sign in anonymously so user can submit abstract before registering.
  static Future<UserCredential?> signInAnonymously() async {
    return _auth.signInAnonymously();
  }

  /// Link anonymous account to email/password so submissions stay with the same uid.
  static Future<UserCredential?> linkAnonymousWithEmailPassword(
    String email,
    String password,
  ) async {
    final user = _auth.currentUser;
    if (user == null || !user.isAnonymous) return null;
    final credential = EmailAuthProvider.credential(
      email: email.trim(),
      password: password,
    );
    return user.linkWithCredential(credential);
  }

  static Future<void> signOut() async {
    await _auth.signOut();
  }

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Returns true if current user has custom claim role == 'admin'.
  static Future<bool> isAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    return token.claims?['role'] == 'admin';
  }

  static Future<UserProfile?> getCurrentUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return FirestoreService.getUserProfile(uid);
  }

  static Future<void> createUserProfileAfterSignUp({
    required String name,
    required String email,
    required String phone,
    required String userType,
    String? institution,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final profile = UserProfile(
      uid: user.uid,
      name: name.trim(),
      email: email,
      phone: phone.trim(),
      role: userType,
      institution: institution?.trim(),
    );
    await FirestoreService.setUserProfile(profile);
  }
}
