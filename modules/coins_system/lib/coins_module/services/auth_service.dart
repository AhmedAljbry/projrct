import 'package:firebase_auth/firebase_auth.dart';

import '../features/auth/domain/auth_repository.dart';
import '../models/coins_user.dart';
import '../utils/module_logger.dart';
import '../utils/safe_executor.dart';

class AuthService {
  AuthService({
    required AuthRepository repository,
    required SafeExecutor safeExecutor,
    required ModuleLogger logger,
    required bool enabled,
  })  : _repository = repository,
        _safeExecutor = safeExecutor,
        _logger = logger,
        _enabled = enabled;

  factory AuthService.noop() => AuthService(
        repository: _NoopAuthRepository(),
        safeExecutor: const SafeExecutor(),
        logger: const ModuleLogger(false),
        enabled: false,
      );

  final AuthRepository _repository;
  final SafeExecutor _safeExecutor;
  final ModuleLogger _logger;
  final bool _enabled;

  bool get isEnabled => _enabled;
  String? get currentUserId => _repository.currentUserId();
  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  Future<CoinsUser?> signInWithGoogle() {
    return _safeExecutor.runAsync(
      _repository.signInWithGoogle,
      fallback: null,
      onError: (error, stackTrace) =>
          _logger.error('Google sign-in failed', error, stackTrace),
    );
  }

  Future<void> signOut() async {
    await _safeExecutor.runAsync(
      () async {
        await _repository.signOut();
        return true;
      },
      fallback: false,
      onError: (error, stackTrace) =>
          _logger.error('Sign-out failed', error, stackTrace),
    );
  }
}

class _NoopAuthRepository implements AuthRepository {
  @override
  String? currentUserId() => null;

  @override
  Future<CoinsUser?> signInWithGoogle() async => null;

  @override
  Future<void> signOut() async {}
}
