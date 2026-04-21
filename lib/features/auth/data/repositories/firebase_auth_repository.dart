import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/crashlytics/crash_reporter.dart';
import 'package:untitled2/core/services/messaging/push_notification_service.dart';
import 'package:untitled2/core/services/remote_config/remote_config_service.dart';
import 'package:untitled2/features/auth/data/datasources/firebase_auth_data_source.dart';
import 'package:untitled2/features/auth/data/datasources/login_reminder_local_data_source.dart';
import 'package:untitled2/features/auth/data/mappers/firebase_auth_failure_mapper.dart';
import 'package:untitled2/features/auth/data/mappers/firebase_user_mapper.dart';
import 'package:untitled2/features/auth/domain/entities/auth_user.dart';
import 'package:untitled2/features/auth/domain/repositories/auth_repository.dart';
import 'package:untitled2/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

@LazySingleton(as: AuthRepository)
class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(
    this._auth,
    this._profileRepository,
    this._analytics,
    this._crashReporter,
    this._pushNotificationService,
    this._remoteConfigService,
    this._talker,
  );

  final FirebaseAuth _auth;
  final UserProfileRepository _profileRepository;
  final AppAnalytics _analytics;
  final CrashReporter _crashReporter;
  final PushNotificationService _pushNotificationService;
  final RemoteConfigService _remoteConfigService;
  final Talker _talker;
  final FirebaseUserMapper _userMapper = const FirebaseUserMapper();
  final FirebaseAuthFailureMapper _failureMapper =
      const FirebaseAuthFailureMapper();
  static const Duration _loginReminderCooldown = Duration(hours: 48);

  FirebaseAuthDataSource get _authDataSource =>
      FirebaseAuthDataSource(_auth, _talker);

  LoginReminderLocalDataSource get _loginReminderLocalDataSource =>
      LoginReminderLocalDataSource(getIt<SharedPreferences>(), _talker);

  @override
  Stream<Either<Failure, AuthUser?>> listenAuthChanges() => watchAuthState();

  @override
  Future<Either<Failure, AuthUser?>> getAuthState() => getCurrentUser();

  @override
  Future<Either<Failure, bool>> shouldShowLoginReminder({DateTime? now}) async {
    try {
      final currentUser = _userMapper.map(_auth.currentUser);
      if (currentUser != null) {
        return right(false);
      }

      final timestamp = _loginReminderLocalDataSource.getLastReminderTimestamp();
      if (timestamp == null) {
        return right(true);
      }

      final elapsed = (now ?? DateTime.now()).difference(timestamp);
      return right(elapsed >= _loginReminderCooldown);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> markLoginReminderDismissed({
    DateTime? timestamp,
  }) async {
    try {
      await _loginReminderLocalDataSource.saveReminderTimestamp(
        timestamp ?? DateTime.now(),
      );
      return right(unit);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Stream<Either<Failure, AuthUser?>> watchAuthState() async* {
    yield* _authDataSource.authStateChanges().asyncMap((user) async {
      try {
        if (user == null) {
          await _analytics.setUserId(null);
          await _crashReporter.setUserId(null);
          return right<Failure, AuthUser?>(null);
        }
        final mappedUser = _userMapper.map(user);
        if (mappedUser != null) {
          await _profileRepository.upsertProfile(mappedUser);
          await _analytics.setUserId(mappedUser.id);
          await _crashReporter.setUserId(mappedUser.id);
          await _crashReporter.setCustomKey(
            'email_verified',
            mappedUser.isEmailVerified,
          );
          await _pushNotificationService.initialize(userId: mappedUser.id);
        }
        return right(mappedUser);
      } catch (error, stackTrace) {
        _talker.error('Auth state watch failed', error, stackTrace);
        return left(_failureMapper.map(error));
      }
    });
  }

  @override
  Future<Either<Failure, AuthUser?>> getCurrentUser() async {
    try {
      final currentUser = await _authDataSource.getCurrentUser();
      return right(_userMapper.map(currentUser));
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _analytics.logLoginAttempt();
      final credential = await _authDataSource.signInWithEmailPassword(
        email: email,
        password: password,
      );
      final user = _userMapper.map(credential.user);
      if (user == null) {
        return left(
          const UnknownFailure(
            'No user profile returned from Firebase.',
            messageKey: 'auth.error.unknown',
          ),
        );
      }
      await _profileRepository.upsertProfile(user);
      await _loginReminderLocalDataSource.clearReminderTimestamp();
      await _analytics.logLoginSuccess(method: 'password');
      return right(user);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, AuthUser>> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      await _analytics.logSignupAttempt();
      final credential = await _authDataSource.signUpWithEmailPassword(
        email: email,
        password: password,
      );
      final user = _userMapper.map(credential.user);
      if (user == null) {
        return left(
          const UnknownFailure(
            'No user profile returned from Firebase.',
            messageKey: 'auth.error.unknown',
          ),
        );
      }
      await _profileRepository.upsertProfile(user);
      await _loginReminderLocalDataSource.clearReminderTimestamp();
      if (_remoteConfigService.requiresEmailVerification) {
        await credential.user?.sendEmailVerification();
      }
      await _analytics.logSignupSuccess(method: 'password');
      return right(user);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email: email);
      await _analytics.logPasswordResetRequested();
      return right(unit);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> sendEmailVerification() async {
    try {
      await _authDataSource.sendEmailVerification();
      return right(unit);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }

  @override
  Future<Either<Failure, Unit>> signOut() async {
    try {
      await _analytics.logLogout();
      await _authDataSource.signOut();
      return right(unit);
    } catch (error) {
      return left(_failureMapper.map(error));
    }
  }
}
