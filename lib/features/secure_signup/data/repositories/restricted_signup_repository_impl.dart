import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/core/logging/app_logger.dart';
import 'package:untitled2/core/network/api_exceptions.dart';
import 'package:untitled2/features/secure_signup/data/datasources/restricted_signup_remote_data_source.dart';
import 'package:untitled2/features/secure_signup/data/models/request_device_override_api_request.dart';
import 'package:untitled2/features/secure_signup/data/models/restricted_signup_api_request.dart';
import 'package:untitled2/features/secure_signup/data/services/firebase_signup_attestation_service.dart';
import 'package:untitled2/features/secure_signup/data/services/installation_identity_service.dart';
import 'package:untitled2/features/secure_signup/domain/entities/restricted_signup_result.dart';
import 'package:untitled2/features/secure_signup/domain/repositories/restricted_signup_repository.dart';

class RestrictedSignupRepositoryImpl implements RestrictedSignupRepository {
  RestrictedSignupRepositoryImpl({
    required RestrictedSignupRemoteDataSource remoteDataSource,
    required InstallationIdentityService installationIdentityService,
    required FirebaseSignupAttestationService signupAttestationService,
    required AppLogger logger,
  })  : _remoteDataSource = remoteDataSource,
        _installationIdentityService = installationIdentityService,
        _signupAttestationService = signupAttestationService,
        _logger = logger;

  final RestrictedSignupRemoteDataSource _remoteDataSource;
  final InstallationIdentityService _installationIdentityService;
  final FirebaseSignupAttestationService _signupAttestationService;
  final AppLogger _logger;
  final Uuid _uuid = const Uuid();

  @override
  Future<Either<Failure, RestrictedSignupResult>> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final installationContext =
          await _installationIdentityService.getContext();
      final attestation =
          await _signupAttestationService.createUserAndCollectTokens(
        email: email,
        password: password,
        displayName: displayName,
      );

      final response = await _remoteDataSource.completeSignup(
        request: RestrictedSignupApiRequest(
          installationId: installationContext.installationId,
          platform: installationContext.platform,
          appVersion: installationContext.appVersion,
          buildNumber: installationContext.buildNumber,
          displayName: displayName,
          email: email,
          requestNonce: _uuid.v4(),
          requestTimestampMs: DateTime.now().millisecondsSinceEpoch,
          riskSignals: installationContext.riskSignals,
        ),
        authToken: attestation.authToken,
        appCheckToken: attestation.appCheckToken,
      );

      _logger.log(
        'Secure signup completed with decision ${response.decision}.',
      );
      return right(response.toDomain());
    } on FirebaseAuthException catch (error, stack) {
      _logger.log(
        'Firebase Auth rejected signup.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      return left(_mapFirebaseAuthFailure(error));
    } on ApiException catch (error, stack) {
      _logger.log(
        'Backend rejected secure signup.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      await _safeRollbackNewUser();
      return left(_mapApiFailure(error));
    } on SocketException catch (error, stack) {
      _logger.log(
        'Network error while completing secure signup.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      await _safeRollbackNewUser();
      return left(const NetworkFailure(
        'We could not reach the signup service. Check your connection and try again.',
      ));
    } catch (error, stack) {
      _logger.log(
        'Unexpected secure signup failure.',
        level: LogLevel.error,
        error: error,
        stack: stack,
      );
      await _safeRollbackNewUser();
      return left(const UnknownFailure(
        'Signup could not be completed right now.',
      ));
    }
  }

  @override
  Future<Either<Failure, void>> requestDeviceOverride({
    required String reason,
  }) async {
    try {
      final installationContext =
          await _installationIdentityService.getContext();
      final headers = await _signupAttestationService.getCurrentHeaders();
      await _remoteDataSource.requestOverride(
        request: RequestDeviceOverrideApiRequest(
          reason: reason,
          installationId: installationContext.installationId,
          platform: installationContext.platform,
          appVersion: installationContext.appVersion,
          buildNumber: installationContext.buildNumber,
          requestNonce: _uuid.v4(),
          requestTimestampMs: DateTime.now().millisecondsSinceEpoch,
          riskSignals: installationContext.riskSignals,
        ),
        authToken: headers['authToken']!,
        appCheckToken: headers['appCheckToken']!,
      );
      return const Right(null);
    } on FirebaseAuthException catch (error, stack) {
      _logger.log(
        'Override request rejected because the user is unauthenticated.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      return left(const PermissionFailure(
        'Sign in again before requesting a manual device review.',
      ));
    } on ApiException catch (error, stack) {
      _logger.log(
        'Backend rejected device override request.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      return left(_mapApiFailure(error));
    } on SocketException catch (error, stack) {
      _logger.log(
        'Network error while requesting a device override.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
      return left(const NetworkFailure(
        'We could not submit your review request. Please try again shortly.',
      ));
    } catch (error, stack) {
      _logger.log(
        'Unexpected device override request failure.',
        level: LogLevel.error,
        error: error,
        stack: stack,
      );
      return left(const UnknownFailure(
        'The review request could not be submitted.',
      ));
    }
  }

  Future<void> _safeRollbackNewUser() async {
    try {
      await _signupAttestationService.rollbackCurrentUser();
    } catch (error, stack) {
      _logger.log(
        'Rollback of freshly created Firebase user failed.',
        level: LogLevel.warn,
        error: error,
        stack: stack,
      );
    }
  }

  Failure _mapFirebaseAuthFailure(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return const ValidationFailure(
          'This email address is already linked to another account.',
        );
      case 'invalid-email':
        return const ValidationFailure(
          'Enter a valid email address.',
        );
      case 'weak-password':
        return const ValidationFailure(
          'Use a stronger password with at least 8 characters.',
        );
      case 'operation-not-allowed':
        return const FirebaseConfigurationFailure(
          'Email and password authentication is not enabled in Firebase Auth.',
        );
      default:
        return ValidationFailure(
          error.message ?? 'Unable to create an account with these details.',
        );
    }
  }

  Failure _mapApiFailure(ApiException error) {
    switch (error.statusCode) {
      case 409:
        return const DeviceAlreadyUsedFailure(
          'This app installation already created an account. If you changed devices legitimately, request a manual review.',
        );
      case 403:
        return const SecurityRejectedFailure(
          'This signup attempt was blocked by security checks.',
        );
      case 412:
        return const SecurityRejectedFailure(
          'App Check attestation failed. Update the app and try again.',
        );
      case 422:
        return const VerificationRequiredFailure(
          'We need extra verification before allowing signup from this installation.',
        );
      case 429:
        return const SecurityRejectedFailure(
          'Too many signup attempts were detected. Please wait before trying again.',
        );
      default:
        return UnknownFailure(
          error.message,
          isRetryable: error.statusCode == null || error.statusCode! >= 500,
        );
    }
  }
}
