import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseSignupAttestation {
  const FirebaseSignupAttestation({
    required this.authToken,
    required this.appCheckToken,
    required this.user,
  });

  final String authToken;
  final String appCheckToken;
  final User user;
}

class FirebaseSignupAttestationService {
  FirebaseSignupAttestationService({
    FirebaseAuth? firebaseAuth,
    FirebaseAppCheck? firebaseAppCheck,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firebaseAppCheck = firebaseAppCheck ?? FirebaseAppCheck.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseAppCheck _firebaseAppCheck;

  Future<FirebaseSignupAttestation> createUserAndCollectTokens({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    await user.updateDisplayName(displayName);
    await user.reload();
    final refreshedUser = _firebaseAuth.currentUser!;
    await refreshedUser.sendEmailVerification();
    final authToken = await refreshedUser.getIdToken(true);
    final appCheckToken = await _firebaseAppCheck.getToken(true);
    return FirebaseSignupAttestation(
      authToken: authToken!,
      appCheckToken: appCheckToken!,
      user: refreshedUser,
    );
  }

  Future<Map<String, String>> getCurrentHeaders() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No authenticated user is available for override requests.',
      );
    }
    final authToken = await user.getIdToken(true);
    final appCheckToken = await _firebaseAppCheck.getToken(true);
    return {
      'authToken': authToken!,
      'appCheckToken': appCheckToken!,
    };
  }

  Future<void> rollbackCurrentUser() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }
}
