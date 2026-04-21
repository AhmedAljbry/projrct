import 'package:dartz/dartz.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/secure_signup/domain/entities/restricted_signup_result.dart';

abstract class RestrictedSignupRepository {
  Future<Either<Failure, RestrictedSignupResult>> signUp({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Either<Failure, void>> requestDeviceOverride({
    required String reason,
  });
}
