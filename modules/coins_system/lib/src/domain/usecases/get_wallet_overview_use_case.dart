import 'package:injectable/injectable.dart';

import '../../core/usecase/use_case.dart';
import '../entities/coins_models.dart';
import '../repositories/coins_repository.dart';

@injectable
class GetWalletOverviewUseCase extends UseCase<WalletOverview, String> {
  GetWalletOverviewUseCase(this._repository);

  final CoinsRepository _repository;

  @override
  ResultFuture<WalletOverview> call(String params) {
    return _repository.getWalletOverview(params);
  }
}
