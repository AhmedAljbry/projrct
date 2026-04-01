import 'package:injectable/injectable.dart';

import '../../core/usecase/use_case.dart';
import '../entities/coins_models.dart';
import '../repositories/coins_repository.dart';

@injectable
class GetTransactionHistoryUseCase
    extends UseCase<TransactionPage, TransactionHistoryQuery> {
  GetTransactionHistoryUseCase(this._repository);

  final CoinsRepository _repository;

  @override
  ResultFuture<TransactionPage> call(TransactionHistoryQuery params) {
    return _repository.getTransactionHistory(params);
  }
}
