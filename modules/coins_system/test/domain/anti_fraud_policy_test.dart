import 'package:flutter_test/flutter_test.dart';

import 'package:coins_system/coins_system.dart';

void main() {
  group('AntiFraudPolicy', () {
    test('rejects rewarded ad claims below the watch threshold', () {
      const AntiFraudPolicy policy = AntiFraudPolicy();

      final result = policy.validateRewardedAdClaim(
        RewardedAdClaim(
          userId: 'user-1',
          adUnitId: 'rewarded-main',
          adNetwork: AdNetworkType.admob,
          sessionId: 'session-1',
          networkTransactionId: 'network-tx-1',
          rewardNonce: 'nonce-1',
          rewardAmount: 20,
          watchedMillis: 1000,
          completedAt: DateTime.now().toUtc(),
          serverSideVerificationToken: 'ssv-token',
          deviceAttestationToken: 'attestation-token',
        ),
      );

      final failure = result.swap().getOrElse(() => throw StateError('Expected left'));
      expect(failure.code, 'anti_fraud_blocked');
    });
  });
}
