import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';

@injectable
class SendEmailVerification {
  SendEmailVerification(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call() => _repository.sendEmailVerification();
}
