import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/services/remote_config/remote_config_keys.dart';
import 'package:untitled2/core/services/remote_config/remote_config_service.dart';

@lazySingleton
class MonetizationRemoteConfigService {
  MonetizationRemoteConfigService(this._remoteConfigService, this._talker);

  final RemoteConfigService _remoteConfigService;
  final Talker _talker;

  MonetizationRemoteConfig get current {
    try {
      final enabled =
          _remoteConfigService.getBool(RemoteConfigKey.monetizationEngineEnabled);
      final rawJson =
          _remoteConfigService.getString(RemoteConfigKey.monetizationConfigJson);
      final parsed = rawJson.isEmpty
          ? MonetizationRemoteConfig.fallback()
          : MonetizationRemoteConfig.fromJson(
              jsonDecode(rawJson) as Map<String, dynamic>,
            );
      return MonetizationRemoteConfig(
        enabled: enabled && parsed.enabled,
        enableInterstitials: parsed.enableInterstitials,
        enableRewarded: parsed.enableRewarded,
        enableRewardedInterstitials: parsed.enableRewardedInterstitials,
        enableNativeAds: parsed.enableNativeAds,
        enableAppOpenAds: parsed.enableAppOpenAds,
        processMode: parsed.processMode,
        saveExportMode: parsed.saveExportMode,
        thresholds: parsed.thresholds,
        weights: parsed.weights,
        cappingRules: parsed.cappingRules,
        processStartPolicy: parsed.processStartPolicy,
        saveResultPolicy: parsed.saveResultPolicy,
        batchOperationPolicy: parsed.batchOperationPolicy,
        retryPolicy: parsed.retryPolicy,
        highConsumptionPolicy: parsed.highConsumptionPolicy,
        appOpenPolicy: parsed.appOpenPolicy,
        nativePlacementPolicy: parsed.nativePlacementPolicy,
      );
    } catch (error, stackTrace) {
      _talker.warning(
        'Using fallback monetization remote config',
        error,
        stackTrace,
      );
      return MonetizationRemoteConfig.fallback();
    }
  }
}
