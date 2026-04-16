import '../features/coins/domain/coins_repository.dart';
import '../models/coin_transaction.dart';
import '../models/coins_user.dart';
import '../models/reward_result.dart';
import '../utils/module_logger.dart';
import '../utils/safe_executor.dart';

class CoinsService {
  CoinsService({
    required CoinsRepository repository,
    required SafeExecutor safeExecutor,
    required ModuleLogger logger,
    required bool enabled,
  })  : _repository = repository,
        _safeExecutor = safeExecutor,
        _logger = logger,
        _enabled = enabled;

  factory CoinsService.noop() => CoinsService(
        repository: _NoopCoinsRepository(),
        safeExecutor: const SafeExecutor(),
        logger: const ModuleLogger(false),
        enabled: false,
      );

  final CoinsRepository _repository;
  final SafeExecutor _safeExecutor;
  final ModuleLogger _logger;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Stream<CoinsUser> watchWallet(String userId) =>
      _repository.watchWallet(userId);

  Future<CoinsUser> getWallet(String userId) {
    return _safeExecutor.runAsync(
      () => _repository.getWallet(userId),
      fallback: CoinsUser.empty(),
      onError: (error, stackTrace) =>
          _logger.error('Wallet fetch failed', error, stackTrace),
    );
  }

  Future<List<CoinTransaction>> getTransactions(String userId,
      {int limit = 20}) {
    return _safeExecutor.runAsync(
      () => _repository.getTransactions(userId, limit: limit),
      fallback: const <CoinTransaction>[],
      onError: (error, stackTrace) =>
          _logger.error('Transactions fetch failed', error, stackTrace),
    );
  }

  Future<RewardResult> claimAdReward(String userId) {
    return _safeExecutor.runAsync(
      () => _repository.claimAdReward(userId),
      fallback: RewardResult.safe(),
      onError: (error, stackTrace) =>
          _logger.error('Reward claim failed', error, stackTrace),
    );
  }
}

class _NoopCoinsRepository implements CoinsRepository {
  @override
  Future<RewardResult> claimAdReward(String userId) async =>
      RewardResult.safe();

  @override
  Future<List<CoinTransaction>> getTransactions(String userId,
          {int limit = 20}) async =>
      const [];

  @override
  Future<CoinsUser> getWallet(String userId) async => CoinsUser.empty();

  @override
  Stream<CoinsUser> watchWallet(String userId) =>
      const Stream<CoinsUser>.empty();
}
