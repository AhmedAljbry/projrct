import 'package:dartz/dartz.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';

class ListenAuthChangesUseCase {
  ListenAuthChangesUseCase(this._repository);

  final AuthRepository _repository;

  Stream<Either<Failure, AuthUser?>> call() => _repository.listenAuthChanges();
}
