import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';
import 'package:untitled2/features/profile/domain/entities/user_profile.dart';

abstract class UserProfileRepository {
  Future<Either<Failure, Unit>> upsertProfile(AuthUser user);

  Future<Either<Failure, UserProfile?>> getProfile(String userId);

  Stream<Either<Failure, UserProfile?>> watchProfile(String userId);

  Future<Either<Failure, Unit>> saveFcmToken({
    required String userId,
    required String token,
  });

  Future<Either<Failure, Unit>> updatePhotoUrl({
    required String userId,
    required String photoUrl,
  });
}
