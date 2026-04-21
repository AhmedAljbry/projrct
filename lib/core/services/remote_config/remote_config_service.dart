import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/services/remote_config/remote_config_keys.dart';

@lazySingleton
class RemoteConfigService {
  RemoteConfigService(this._remoteConfig, this._talker);

  final FirebaseRemoteConfig _remoteConfig;
  final Talker _talker;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(
            seconds: AppConstants.remoteConfigFetchTimeoutSeconds,
          ),
          minimumFetchInterval: const Duration(
            hours: AppConstants.remoteConfigMinimumFetchIntervalHours,
          ),
        ),
      );
      await _remoteConfig.setDefaults(_defaults);
      await _remoteConfig.fetchAndActivate();
    } catch (error, stackTrace) {
      _talker.warning('Remote Config initialization failed', error, stackTrace);
    }
  }

  bool get isMaintenanceMode =>
      _remoteConfig.getBool(RemoteConfigKey.maintenanceMode.key);

  String get minSupportedVersion =>
      _remoteConfig.getString(RemoteConfigKey.minSupportedVersion.key);

  // Temporarily disable email verification gating during local development.
  bool get requiresEmailVerification => false;

  bool get experimentalAuthHero =>
      _remoteConfig.getBool(RemoteConfigKey.experimentalAuthHero.key);

  bool getBool(RemoteConfigKey key) => _remoteConfig.getBool(key.key);

  String getString(RemoteConfigKey key) => _remoteConfig.getString(key.key);

  int getInt(RemoteConfigKey key) => _remoteConfig.getInt(key.key);

  double getDouble(RemoteConfigKey key) => _remoteConfig.getDouble(key.key);

  Map<String, Object> get _defaults => {
        for (final key in RemoteConfigKey.values) key.key: key.defaultValue,
      };
}
