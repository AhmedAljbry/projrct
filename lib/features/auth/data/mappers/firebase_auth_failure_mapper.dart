import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled2/core/error/failure.dart';

class FirebaseAuthFailureMapper {
  const FirebaseAuthFailureMapper();

  Failure map(Object error) {
    if (error is! FirebaseAuthException) {
      return const UnknownFailure(
        'An unexpected authentication error occurred.',
        messageKey: 'auth.error.unknown',
      );
    }
    return switch (error.code) {
      'invalid-email' => const UnknownFailure(
          'The email address is invalid.',
          messageKey: 'auth.error.invalidEmail',
        ),
      'user-not-found' => const UnknownFailure(
          'No account was found for that email.',
          messageKey: 'auth.error.userNotFound',
        ),
      'wrong-password' || 'invalid-credential' => const UnknownFailure(
          'The email or password is incorrect.',
          messageKey: 'auth.error.invalidCredential',
        ),
      'email-already-in-use' => const UnknownFailure(
          'An account already exists for that email.',
          messageKey: 'auth.error.emailAlreadyInUse',
        ),
      'weak-password' => const UnknownFailure(
          'The password does not meet security requirements.',
          messageKey: 'auth.error.weakPassword',
        ),
      'too-many-requests' => const UnknownFailure(
          'Too many attempts were made. Please try again later.',
          messageKey: 'auth.error.tooManyRequests',
        ),
      'network-request-failed' => const UnknownFailure(
          'Network connection failed.',
          messageKey: 'auth.error.network',
        ),
      _ => UnknownFailure(
          error.message ?? 'Authentication failed.',
          messageKey: 'auth.error.unknown',
        ),
    };
  }
}
