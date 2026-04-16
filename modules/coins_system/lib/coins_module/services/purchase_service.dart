import '../features/payments/domain/payments_repository.dart';
import '../models/product_offer.dart';
import '../models/reward_result.dart';
import '../utils/module_logger.dart';
import '../utils/safe_executor.dart';

class PurchaseService {
  PurchaseService({
    required PaymentsRepository repository,
    required SafeExecutor safeExecutor,
    required ModuleLogger logger,
    required bool enabled,
  })  : _repository = repository,
        _safeExecutor = safeExecutor,
        _logger = logger,
        _enabled = enabled;

  factory PurchaseService.noop() => PurchaseService(
        repository: _NoopPaymentsRepository(),
        safeExecutor: const SafeExecutor(),
        logger: const ModuleLogger(false),
        enabled: false,
      );

  final PaymentsRepository _repository;
  final SafeExecutor _safeExecutor;
  final ModuleLogger _logger;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Future<List<ProductOffer>> loadProducts() {
    return _safeExecutor.runAsync(
      _repository.loadProducts,
      fallback: const <ProductOffer>[],
      onError: (error, stackTrace) =>
          _logger.error('Product load failed', error, stackTrace),
    );
  }

  Future<RewardResult> buyProduct(String productId) {
    return _safeExecutor.runAsync(
      () => _repository.buyProduct(productId),
      fallback: RewardResult.safe('Purchase unavailable'),
      onError: (error, stackTrace) =>
          _logger.error('Purchase failed', error, stackTrace),
    );
  }

  Future<void> dispose() async {
    await _safeExecutor.runAsync(
      () async {
        await _repository.dispose();
        return true;
      },
      fallback: false,
      onError: (error, stackTrace) =>
          _logger.error('Purchase cleanup failed', error, stackTrace),
    );
  }
}

class _NoopPaymentsRepository implements PaymentsRepository {
  @override
  Future<RewardResult> buyProduct(String productId) async =>
      RewardResult.safe('Purchase unavailable');

  @override
  Future<void> dispose() async {}

  @override
  Future<List<ProductOffer>> loadProducts() async => const [];
}
