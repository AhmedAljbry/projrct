import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';

class FirebaseUserMapper {
  const FirebaseUserMapper();

  AuthUser? map(User? user) {
    if (user == null || user.email == null) {
      return null;
    }
    return AuthUser(
      id: user.uid,
      email: user.email!,
      isEmailVerified: user.emailVerified,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }
}
