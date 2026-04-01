import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/coins_failures.dart';
import '../../core/security/anti_fraud_policy.dart';
import '../../core/security/local_claim_guard.dart';
import '../../core/usecase/use_case.dart';
import '../entities/coins_models.dart';
import '../repositories/coins_repository.dart';

@injectable
class ClaimRewardedAdUseCase
    extends UseCase<LedgerMutationResult, RewardedAdClaim> {
  ClaimRewardedAdUseCase(
    this._repository,
    this._antiFraudPolicy,
    this._claimGuard,
  );

  final CoinsRepository _repository;
  final AntiFraudPolicy _antiFraudPolicy;
  final LocalClaimGuard _claimGuard;

  @override
  ResultFuture<LedgerMutationResult> call(RewardedAdClaim params) async {
    final validation = _antiFraudPolicy.validateRewardedAdClaim(params);
    if (validation.isLeft()) {
      return validation.fold(left, (_) => throw StateError('Unreachable'));
    }

    final bool reserved = await _claimGuard.reserve(params.idempotencyKey);
    if (!reserved) {
      return left(
        DuplicateRewardFailure(
          'Rewarded ad already processed for this transaction.',
          meta: <String, dynamic>{'idempotencyKey': params.idempotencyKey},
        ),
      );
    }

    final result = await _repository.claimRewardedAd(params);
    if (result.isLeft()) {
      await _claimGuard.release(params.idempotencyKey);
    } else {
      await _claimGuard.commit(params.idempotencyKey);
    }
    return result;
  }
}
