import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';

class ShouldShowLoginReminderUseCase {
  ShouldShowLoginReminderUseCase(this._repository);

  final AuthRepository _repository;

  Future<Either<Failure, bool>> call({DateTime? now}) {
    return _repository.shouldShowLoginReminder(now: now);
  }
}
