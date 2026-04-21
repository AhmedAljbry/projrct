import 'package:dartz/dartz.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/secure_signup/domain/entities/restricted_signup_result.dart';
import 'package:untitled2/features/secure_signup/domain/repositories/restricted_signup_repository.dart';

class CreateRestrictedAccountUseCase {
  const CreateRestrictedAccountUseCase(this._repository);

  final RestrictedSignupRepository _repository;

  Future<Either<Failure, RestrictedSignupResult>> call({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _repository.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
