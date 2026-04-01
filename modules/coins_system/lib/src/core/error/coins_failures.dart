import 'failure.dart';

class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.meta,
  }) : super(code: 'validation_failed');
}

class DuplicateRewardFailure extends Failure {
  const DuplicateRewardFailure(
    super.message, {
    super.meta,
  }) : super(code: 'duplicate_reward');
}

class AntiFraudFailure extends Failure {
  const AntiFraudFailure(
    super.message, {
    super.meta,
  }) : super(code: 'anti_fraud_blocked');
}

class InsufficientBalanceFailure extends Failure {
  const InsufficientBalanceFailure(
    super.message, {
    super.meta,
  }) : super(code: 'insufficient_balance');
}

class PurchaseVerificationFailure extends Failure {
  const PurchaseVerificationFailure(
    super.message, {
    super.meta,
    super.isRetryable = true,
  }) : super(code: 'purchase_verification_failed');
}

class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    super.meta,
    super.isRetryable = true,
  }) : super(code: 'network_error');
}

class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.meta,
    super.isRetryable = true,
  }) : super(code: 'server_error');
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(
    super.message, {
    super.meta,
    super.isRetryable = true,
  }) : super(code: 'unexpected_error');
}
