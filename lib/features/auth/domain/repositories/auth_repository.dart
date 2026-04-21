import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  Stream<Either<Failure, AuthUser?>> listenAuthChanges();

  Future<Either<Failure, AuthUser?>> getAuthState();

  Future<Either<Failure, bool>> shouldShowLoginReminder({DateTime? now});

  Future<Either<Failure, Unit>> markLoginReminderDismissed({
    DateTime? timestamp,
  });

  Stream<Either<Failure, AuthUser?>> watchAuthState();

  Future<Either<Failure, AuthUser?>> getCurrentUser();

  Future<Either<Failure, AuthUser>> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, AuthUser>> signUpWithEmailPassword({
    required String email,
    required String password,
  });

  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  });

  Future<Either<Failure, Unit>> sendEmailVerification();

  Future<Either<Failure, Unit>> signOut();
}
