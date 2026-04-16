import '../features/device/data/device_fingerprint_data_source.dart';
import '../models/device_snapshot.dart';
import '../utils/module_logger.dart';
import '../utils/safe_executor.dart';

class DeviceService {
  DeviceService({
    required DeviceFingerprintDataSource? dataSource,
    required SafeExecutor safeExecutor,
    required ModuleLogger logger,
    required bool enabled,
  })  : _dataSource = dataSource,
        _safeExecutor = safeExecutor,
        _logger = logger,
        _enabled = enabled;

  factory DeviceService.noop() => DeviceService(
        dataSource: null,
        safeExecutor: const SafeExecutor(),
        logger: const ModuleLogger(false),
        enabled: false,
      );

  final DeviceFingerprintDataSource? _dataSource;
  final SafeExecutor _safeExecutor;
  final ModuleLogger _logger;
  final bool _enabled;

  bool get isEnabled => _enabled;

  Future<DeviceSnapshot?> getSnapshot() {
    return _safeExecutor.runAsync(
      () async {
        final dataSource = _dataSource;
        if (dataSource == null) {
          return null;
        }
        final fingerprint = await dataSource.createFingerprint();
        return DeviceSnapshot(
          deviceHash: fingerprint.deviceHash,
          fingerprintSignature: fingerprint.fingerprintSignature,
          installTimestamp: fingerprint.installTimestamp,
          installId: fingerprint.installId,
          attributes: fingerprint.attributes,
        );
      },
      fallback: null,
      onError: (error, stackTrace) =>
          _logger.error('Device snapshot failed', error, stackTrace),
    );
  }
}
