import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/coins_failures.dart';
import '../../core/security/anti_fraud_policy.dart';
import '../../core/security/local_claim_guard.dart';
import '../../core/usecase/use_case.dart';
import '../entities/coins_models.dart';
import '../repositories/coins_repository.dart';

@injectable
class SpendCoinsUseCase extends UseCase<LedgerMutationResult, SpendCoinsCommand> {
  SpendCoinsUseCase(
    this._repository,
    this._antiFraudPolicy,
    this._claimGuard,
  );

  final CoinsRepository _repository;
  final AntiFraudPolicy _antiFraudPolicy;
  final LocalClaimGuard _claimGuard;

  @override
  ResultFuture<LedgerMutationResult> call(SpendCoinsCommand params) async {
    final validation = _antiFraudPolicy.validateSpend(params);
    if (validation.isLeft()) {
      return validation.fold(left, (_) => throw StateError('Unreachable'));
    }

    if (params.currentAvailableBalance < params.amount) {
      return left(
        InsufficientBalanceFailure(
          'Not enough coins to unlock this premium feature.',
          meta: <String, dynamic>{
            'required': params.amount,
            'available': params.currentAvailableBalance,
          },
        ),
      );
    }

    final String idempotencyKey = params.resolvedIdempotencyKey;
    final bool reserved = await _claimGuard.reserve(idempotencyKey);
    if (!reserved) {
      return left(
        DuplicateRewardFailure(
          'Spend request already processed for this reference.',
          meta: <String, dynamic>{'idempotencyKey': idempotencyKey},
        ),
      );
    }

    final result = await _repository.spendCoins(params);
    if (result.isLeft()) {
      await _claimGuard.release(idempotencyKey);
    } else {
      await _claimGuard.commit(idempotencyKey);
    }
    return result;
  }
}
