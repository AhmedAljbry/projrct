sealed class Failure {
  final String message;
  final String code;
  final String? messageKey;
  final Map<String, Object?> meta;
  final bool isRetryable;

  const Failure(
    this.message, {
    required this.code,
    this.messageKey,
    this.meta = const {},
    this.isRetryable = false,
  });
}

class PermissionFailure extends Failure {
  const PermissionFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = true,
  }) : super(
          code: 'permission_denied',
          messageKey: messageKey ?? 'errors.permissionDenied',
        );
}

class UnknownFailure extends Failure {
  const UnknownFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable,
  }) : super(
          code: 'unknown',
          messageKey: messageKey ?? 'errors.unknown',
        );
}

class NetworkFailure extends Failure {
  const NetworkFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = true,
  }) : super(
          code: 'network_error',
          messageKey: messageKey ?? 'errors.network',
        );
}

class FirebaseConfigurationFailure extends Failure {
  const FirebaseConfigurationFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = false,
  }) : super(
          code: 'firebase_not_configured',
          messageKey: messageKey ?? 'errors.firebaseNotConfigured',
        );
}

class DeviceAlreadyUsedFailure extends Failure {
  const DeviceAlreadyUsedFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = false,
  }) : super(
          code: 'installation_already_registered',
          messageKey: messageKey ?? 'errors.installationAlreadyRegistered',
        );
}

class VerificationRequiredFailure extends Failure {
  const VerificationRequiredFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = false,
  }) : super(
          code: 'extra_verification_required',
          messageKey: messageKey ?? 'errors.extraVerificationRequired',
        );
}

class SecurityRejectedFailure extends Failure {
  const SecurityRejectedFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = false,
  }) : super(
          code: 'security_rejected',
          messageKey: messageKey ?? 'errors.securityRejected',
        );
}

class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = false,
  }) : super(
          code: 'validation_error',
          messageKey: messageKey ?? 'errors.validation',
        );
}

/// ---- Segmentation ----
class SegmentationFailure extends Failure {
  const SegmentationFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = true,
  }) : super(
          code: 'segmentation_failed',
          messageKey: messageKey ?? 'errors.segmentationFailed',
        );
}

/// ---- Save ----
class SaveFailure extends Failure {
  const SaveFailure(
    super.message, {
    String? messageKey,
    super.meta,
    super.isRetryable = true,
  }) : super(
          code: 'save_failed',
          messageKey: messageKey ?? 'errors.saveFailed',
        );
}
