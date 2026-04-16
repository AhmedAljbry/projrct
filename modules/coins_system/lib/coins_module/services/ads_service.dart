import '../features/ads/domain/ads_repository.dart';
import '../models/reward_result.dart';
import '../utils/module_logger.dart';
import '../utils/safe_executor.dart';
import 'coins_service.dart';

class AdsService {
  AdsService({
    required AdsRepository repository,
    required CoinsService coinsService,
    required SafeExecutor safeExecutor,
    required ModuleLogger logger,
    required bool enabled,
  })  : _repository = repository,
        _coinsService = coinsService,
        _safeExecutor = safeExecutor,
        _logger = logger,
        _enabled = enabled;

  factory AdsService.noop() => AdsService(
        repository: _NoopAdsRepository(),
        coinsService: CoinsService.noop(),
        safeExecutor: const SafeExecutor(),
        logger: const ModuleLogger(false),
        enabled: false,
      );

  final AdsRepository _repository;
  final CoinsService _coinsService;
  final SafeExecutor _safeExecutor;
  final ModuleLogger _logger;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Future<bool> preloadRewardedAd() {
    return _safeExecutor.runAsync(
      _repository.preloadRewardedAd,
      fallback: false,
      onError: (error, stackTrace) =>
          _logger.error('Rewarded ad preload failed', error, stackTrace),
    );
  }

  Future<RewardResult> showRewardedAdAndClaim({
    required String userId,
  }) async {
    RewardResult outcome = RewardResult.safe('Reward not granted');
    final shown = await _safeExecutor.runAsync(
      () => _repository.showRewardedAd(
        onRewarded: () async {
          outcome = await _coinsService.claimAdReward(userId);
        },
      ),
      fallback: false,
      onError: (error, stackTrace) =>
          _logger.error('Rewarded ad failed', error, stackTrace),
    );
    if (!shown && !outcome.success) {
      return RewardResult.safe('Ad not completed');
    }
    return outcome;
  }
}

class _NoopAdsRepository implements AdsRepository {
  @override
  Future<bool> preloadRewardedAd() async => false;

  @override
  Future<bool> showRewardedAd(
          {required Future<void> Function() onRewarded}) async =>
      false;
}
