import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SignUpWithEmailPassword {
  SignUpWithEmailPassword(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, AuthUser>> call({
    required String email,
    required String password,
  }) {
    return _repository.signUpWithEmailPassword(
      email: email,
      password: password,
    );
  }
}
