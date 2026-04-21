import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';

class MarkLoginReminderDismissedUseCase {
  MarkLoginReminderDismissedUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, Unit>> call({DateTime? timestamp}) {
    return _repository.markLoginReminderDismissed(timestamp: timestamp);
  }
}
