import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔐 ADMIN CREDENTIALS (YOU CONTROL THESE)
  static const String adminEmail = "admin@dragncode.com";
  static const String adminPassword = "Admin@123";

  /* ================= SIGN UP ================= */
  /// Sign up a new user (AUTH ONLY)
  /// Firestore user profile must be created separately using FirestoreService
  Future<String?> signUp({
    required String email,
    required String password,
  }) async {
    final result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user?.uid;
  }

  /* ================= LOGIN ================= */
  /// Login existing user
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    final result = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return result.user?.uid;
  }

  /* ================= ADMIN CHECK ================= */
  /// 🔥 FAST ADMIN CHECK (NO FIRESTORE READ)
  bool isAdmin({
    required String email,
    required String password,
  }) {
    return email == adminEmail && password == adminPassword;
  }

  /* ================= CURRENT USER ================= */
  User? get currentUser => _auth.currentUser;
  String? get currentUid => _auth.currentUser?.uid;
  bool get isLoggedIn => _auth.currentUser != null;

  /* ================= LOGOUT ================= */
  /// Logout user
  Future<void> logout() async {
    await _auth.signOut();
  }

  /* ================= PASSWORD RESET ================= */
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /* ================= UPDATE USER INFO ================= */

  /// Update display name and/or profile picture
  Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    if (displayName != null) await user.updateDisplayName(displayName);
    if (photoURL != null) await user.updatePhotoURL(photoURL);

    await user.reload(); // Refresh user info
  }

  /// Update email (Firebase Auth 6.x compatible)
  Future<void> updateEmail({
    required String newEmail,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Re-authenticate
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // 🔥 Firebase 6.x method
    await user.verifyBeforeUpdateEmail(newEmail);

    await user.reload();
  }

  /// Update password (requires current password for reauthentication)
  Future<void> updatePassword({
    required String newPassword,
    required String currentPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("No user logged in");

    // Reauthenticate user first
    final credential = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(credential);

    // Update password
    await user.updatePassword(newPassword);
    await user.reload();
  }
}
