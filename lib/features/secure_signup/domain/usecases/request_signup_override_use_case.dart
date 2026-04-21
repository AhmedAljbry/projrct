import 'package:dartz/dartz.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/secure_signup/domain/repositories/restricted_signup_repository.dart';

class RequestSignupOverrideUseCase {
  const RequestSignupOverrideUseCase(this._repository);

  final RestrictedSignupRepository _repository;

  Future<Either<Failure, void>> call({required String reason}) {
    return _repository.requestDeviceOverride(reason: reason);
  }
}
