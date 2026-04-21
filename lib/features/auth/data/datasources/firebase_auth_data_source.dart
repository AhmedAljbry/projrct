import 'package:firebase_auth/firebase_auth.dart';
import 'package:talker/talker.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource(
    this._auth,
    this._talker,
  );

  final FirebaseAuth _auth;
  final Talker _talker;

  Stream<User?> authStateChanges() => _auth.authStateChanges().map((user) {
        _talker.debug('Firebase auth state changed: ${user?.uid ?? 'guest'}');
        return user;
      });

  Future<User?> getCurrentUser() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendEmailVerification() {
    return _auth.currentUser?.sendEmailVerification() ?? Future.value();
  }

  Future<void> signOut() => _auth.signOut();
}
