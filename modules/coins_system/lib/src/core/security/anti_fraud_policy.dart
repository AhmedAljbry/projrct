import 'package:dartz/dartz.dart';

import '../error/coins_failures.dart';
import '../error/failure.dart';
import '../../domain/entities/coins_models.dart';

class AntiFraudPolicy {
  const AntiFraudPolicy({
    this.maxTaskReward = 500,
    this.maxRewardedAdReward = 150,
    this.maxSpendAmount = 200000,
    this.minRewardedAdWatchMillis = 25000,
    this.taskClaimFreshness = const Duration(minutes: 30),
    this.adClaimFreshness = const Duration(minutes: 10),
    this.purchaseFreshness = const Duration(hours: 24),
    this.maxFutureClockSkew = const Duration(minutes: 5),
  });

  final int maxTaskReward;
  final int maxRewardedAdReward;
  final int maxSpendAmount;
  final int minRewardedAdWatchMillis;
  final Duration taskClaimFreshness;
  final Duration adClaimFreshness;
  final Duration purchaseFreshness;
  final Duration maxFutureClockSkew;

  Either<Failure, Unit> validateTaskClaim(TaskRewardClaim claim) {
    final requiredFieldFailure = _requireFields(<String, String>{
      'taskId': claim.taskId,
      'completionId': claim.completionId,
      'serverProof': claim.serverProof,
      'deviceAttestationToken': claim.deviceAttestationToken,
    });
    if (requiredFieldFailure != null) {
      return left(requiredFieldFailure);
    }
    if (claim.rewardAmount <= 0 || claim.rewardAmount > maxTaskReward) {
      return left(
        ValidationFailure(
          'Task reward amount is out of allowed bounds.',
          meta: <String, dynamic>{'rewardAmount': claim.rewardAmount},
        ),
      );
    }
    final timestampFailure = _validateTimestamp(
      occurredAt: claim.completedAt,
      freshnessWindow: taskClaimFreshness,
      source: 'task_reward',
    );
    if (timestampFailure != null) {
      return left(timestampFailure);
    }
    return right(unit);
  }

  Either<Failure, Unit> validateRewardedAdClaim(RewardedAdClaim claim) {
    final requiredFieldFailure = _requireFields(<String, String>{
      'adUnitId': claim.adUnitId,
      'sessionId': claim.sessionId,
      'networkTransactionId': claim.networkTransactionId,
      'rewardNonce': claim.rewardNonce,
      'serverSideVerificationToken': claim.serverSideVerificationToken,
      'deviceAttestationToken': claim.deviceAttestationToken,
    });
    if (requiredFieldFailure != null) {
      return left(requiredFieldFailure);
    }
    if (claim.rewardAmount <= 0 || claim.rewardAmount > maxRewardedAdReward) {
      return left(
        ValidationFailure(
          'Rewarded ad amount is out of allowed bounds.',
          meta: <String, dynamic>{'rewardAmount': claim.rewardAmount},
        ),
      );
    }
    if (claim.watchedMillis < minRewardedAdWatchMillis) {
      return left(
        AntiFraudFailure(
          'Rewarded ad claim is below the minimum watched duration.',
          meta: <String, dynamic>{'watchedMillis': claim.watchedMillis},
        ),
      );
    }
    final timestampFailure = _validateTimestamp(
      occurredAt: claim.completedAt,
      freshnessWindow: adClaimFreshness,
      source: 'rewarded_ad',
    );
    if (timestampFailure != null) {
      return left(timestampFailure);
    }
    return right(unit);
  }

  Either<Failure, Unit> validatePurchase(PurchaseVerificationRequest request) {
    final requiredFieldFailure = _requireFields(<String, String>{
      'packageSku': request.packageSku,
      'productId': request.productId,
      'transactionId': request.transactionId,
      'purchaseToken': request.purchaseToken,
      'signedPayload': request.signedPayload,
      'deviceAttestationToken': request.deviceAttestationToken,
    });
    if (requiredFieldFailure != null) {
      return left(requiredFieldFailure);
    }
    if (request.priceMicros <= 0) {
      return left(
        PurchaseVerificationFailure(
          'Purchase amount must be positive.',
          meta: <String, dynamic>{'priceMicros': request.priceMicros},
        ),
      );
    }
    final timestampFailure = _validateTimestamp(
      occurredAt: request.completedAt,
      freshnessWindow: purchaseFreshness,
      source: 'purchase',
    );
    if (timestampFailure != null) {
      return left(timestampFailure);
    }
    return right(unit);
  }

  Either<Failure, Unit> validateSpend(SpendCoinsCommand command) {
    final requiredFieldFailure = _requireFields(<String, String>{
      'featureId': command.featureId,
      'referenceId': command.referenceId,
      'idempotencyKey': command.resolvedIdempotencyKey,
    });
    if (requiredFieldFailure != null) {
      return left(requiredFieldFailure);
    }
    if (command.amount <= 0 || command.amount > maxSpendAmount) {
      return left(
        ValidationFailure(
          'Spend amount is invalid.',
          meta: <String, dynamic>{'amount': command.amount},
        ),
      );
    }
    return right(unit);
  }

  Either<Failure, Unit> validateVelocity({
    required int observedAttempts,
    required int allowedAttempts,
    required String action,
  }) {
    if (observedAttempts > allowedAttempts) {
      return left(
        AntiFraudFailure(
          'Velocity limit reached for $action.',
          meta: <String, dynamic>{
            'observedAttempts': observedAttempts,
            'allowedAttempts': allowedAttempts,
            'action': action,
          },
        ),
      );
    }
    return right(unit);
  }

  Failure? _requireFields(Map<String, String> fields) {
    for (final MapEntry<String, String> entry in fields.entries) {
      if (entry.value.trim().isEmpty) {
        return ValidationFailure(
          '${entry.key} is required.',
          meta: <String, dynamic>{'field': entry.key},
        );
      }
    }
    return null;
  }

  Failure? _validateTimestamp({
    required DateTime occurredAt,
    required Duration freshnessWindow,
    required String source,
  }) {
    final DateTime now = DateTime.now().toUtc();
    final DateTime utcOccurredAt = occurredAt.toUtc();

    if (utcOccurredAt.isAfter(now.add(maxFutureClockSkew))) {
      return AntiFraudFailure(
        'Future-dated timestamp detected for $source.',
        meta: <String, dynamic>{
          'occurredAt': utcOccurredAt.toIso8601String(),
          'now': now.toIso8601String(),
        },
      );
    }

    if (now.difference(utcOccurredAt) > freshnessWindow) {
      return AntiFraudFailure(
        'Stale claim detected for $source.',
        meta: <String, dynamic>{
          'occurredAt': utcOccurredAt.toIso8601String(),
          'freshnessWindowSeconds': freshnessWindow.inSeconds,
        },
      );
    }

    return null;
  }
}
