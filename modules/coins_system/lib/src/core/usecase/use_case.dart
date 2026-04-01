import 'package:dartz/dartz.dart';

import '../error/failure.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;

abstract class UseCase<T, Params> {
  ResultFuture<T> call(Params params);
}

class NoParams {
  const NoParams();
}
