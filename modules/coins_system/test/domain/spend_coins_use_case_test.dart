import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:coins_system/coins_system.dart';

void main() {
  group('Coins use cases', () {
    test('returns insufficient balance before repository call', () async {
      final repository = _FakeCoinsRepository();
      final useCase = SpendCoinsUseCase(
        repository,
        const AntiFraudPolicy(),
        InMemoryLocalClaimGuard(),
      );

      final result = await useCase(
        const SpendCoinsCommand(
          userId: 'user-1',
          featureId: 'pro-export',
          referenceId: 'unlock-1',
          amount: 120,
          currentAvailableBalance: 50,
        ),
      );

      final failure = result.swap().getOrElse(() => throw StateError('Expected left'));
      expect(failure.code, 'insufficient_balance');
      expect(repository.spendCalls, 0);
    });

    test('prevents duplicate task reward claims using the local guard', () async {
      final repository = _FakeCoinsRepository();
      final useCase = ClaimTaskRewardUseCase(
        repository,
        const AntiFraudPolicy(),
        InMemoryLocalClaimGuard(),
      );

      final claim = TaskRewardClaim(
        userId: 'user-1',
        taskId: 'remove-background',
        completionId: 'completion-1',
        rewardAmount: 35,
        completedAt: DateTime.now().toUtc(),
        serverProof: 'signed-proof',
        deviceAttestationToken: 'attestation-token',
      );

      final first = await useCase(claim);
      final second = await useCase(claim);

      expect(first.isRight(), true);
      expect(
        second.swap().getOrElse(() => throw StateError('Expected left')).code,
        'duplicate_reward',
      );
      expect(repository.taskClaimCalls, 1);
    });
  });
}

class _FakeCoinsRepository implements CoinsRepository {
  int spendCalls = 0;
  int taskClaimCalls = 0;

  @override
  Future<Either<Failure, LedgerMutationResult>> claimRewardedAd(
    RewardedAdClaim claim,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> claimTaskReward(
    TaskRewardClaim claim,
  ) async {
    taskClaimCalls += 1;
    return right(_sampleMutationResult(claim.userId, claim.idempotencyKey, 435));
  }

  @override
  Future<Either<Failure, TransactionPage>> getTransactionHistory(
    TransactionHistoryQuery query,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, WalletOverview>> getWalletOverview(String userId) {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> spendCoins(
    SpendCoinsCommand command,
  ) async {
    spendCalls += 1;
    return right(
      _sampleMutationResult(
        command.userId,
        command.resolvedIdempotencyKey,
        command.currentAvailableBalance - command.amount,
      ),
    );
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> verifyPurchase(
    PurchaseVerificationRequest request,
  ) {
    throw UnimplementedError();
  }

  LedgerMutationResult _sampleMutationResult(
    String userId,
    String idempotencyKey,
    int updatedBalance,
  ) {
    final balance = WalletBalance(
      available: updatedBalance,
      reserved: 0,
      lifetimeEarned: 500,
      lifetimeSpent: 65,
      updatedAt: DateTime.now().toUtc(),
    );

    return LedgerMutationResult(
      walletBalance: balance,
      transaction: CoinTransaction(
        id: 'tx-$idempotencyKey',
        userId: userId,
        direction: CoinTransactionDirection.credit,
        type: CoinTransactionType.taskReward,
        status: LedgerEntryStatus.settled,
        amount: 35,
        balanceAfter: updatedBalance,
        title: 'Reward applied',
        referenceId: idempotencyKey,
        occurredAt: DateTime.now().toUtc(),
      ),
      reviewStatus: RewardReviewStatus.approved,
      idempotencyKey: idempotencyKey,
    );
  }
}
