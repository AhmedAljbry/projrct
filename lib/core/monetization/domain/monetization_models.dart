import 'dart:convert';

enum MonetizationPlacement {
  processStart,
  saveResult,
  batchOperationStart,
  retryHeavyOperation,
  freeUserHighConsumption,
  appOpen,
}

enum MonetizationAdFormat {
  none,
  interstitial,
  rewarded,
  rewardedInterstitial,
  native,
  appOpen,
}

enum MonetizationUserSegment {
  newUser,
  lightUser,
  activeUser,
  heavyApiConsumer,
  powerUser,
  premium,
  cooldownProtected,
}

enum SaveExportMonetizationMode {
  beforeExport,
  afterRenderBeforeSave,
  rewardedUpsell,
}

enum ProcessMonetizationMode {
  beforeProcess,
  afterQueueAccepted,
  disabled,
}

enum MonetizationSkipReason {
  disabled,
  premium,
  noInventory,
  noInternet,
  cooldown,
  fatigue,
  sessionCap,
  placementCap,
  criticalFlow,
  activeGesture,
  recentFullScreen,
  recentReward,
  lowPriority,
  unsupported,
}

enum MonetizationOutcome {
  shown,
  skipped,
  unavailable,
  dismissed,
  rewarded,
  failed,
}

final class MonetizationOperationContext {
  const MonetizationOperationContext({
    required this.operationId,
    required this.operationType,
    required this.estimatedApiCostUnits,
    this.isBatch = false,
    this.isRetry = false,
    this.requiresImmediateExecution = false,
    this.isCriticalFlow = false,
    this.allowRewardedUpsell = false,
    this.exportCountIncrement = 0,
    this.saveCountIncrement = 0,
    this.sessionDepth = 0,
    this.metadata = const <String, Object?>{},
  });

  final String operationId;
  final String operationType;
  final double estimatedApiCostUnits;
  final bool isBatch;
  final bool isRetry;
  final bool requiresImmediateExecution;
  final bool isCriticalFlow;
  final bool allowRewardedUpsell;
  final int exportCountIncrement;
  final int saveCountIncrement;
  final int sessionDepth;
  final Map<String, Object?> metadata;
}

final class MonetizationUiState {
  const MonetizationUiState({
    required this.routeName,
    this.isEditingGestureActive = false,
    this.isOffline = false,
    this.isForeground = true,
    this.allowFullScreenAds = true,
    this.allowNativeAds = true,
  });

  final String routeName;
  final bool isEditingGestureActive;
  final bool isOffline;
  final bool isForeground;
  final bool allowFullScreenAds;
  final bool allowNativeAds;
}

final class UserConsumptionSnapshot {
  const UserConsumptionSnapshot({
    required this.dateKey,
    required this.sessionId,
    required this.totalSessions,
    required this.sessionDepth,
    required this.apiCallsToday,
    required this.apiCallsThisSession,
    required this.expensiveOperationsToday,
    required this.expensiveOperationsThisSession,
    required this.saveCountToday,
    required this.exportCountToday,
    required this.retryCountToday,
    required this.failedCostlyAttemptsToday,
    required this.fullScreenAdsSession,
    required this.fullScreenAdsToday,
    required this.processPlacementAdsSession,
    required this.savePlacementAdsSession,
    required this.lastAdShownAt,
    required this.lastRewardedAdAt,
    required this.lastInterstitialAdAt,
    required this.fatigueScore,
    required this.isPremium,
    required this.hasNoAdsEntitlement,
  });

  final String dateKey;
  final String sessionId;
  final int totalSessions;
  final int sessionDepth;
  final int apiCallsToday;
  final int apiCallsThisSession;
  final int expensiveOperationsToday;
  final int expensiveOperationsThisSession;
  final int saveCountToday;
  final int exportCountToday;
  final int retryCountToday;
  final int failedCostlyAttemptsToday;
  final int fullScreenAdsSession;
  final int fullScreenAdsToday;
  final int processPlacementAdsSession;
  final int savePlacementAdsSession;
  final DateTime? lastAdShownAt;
  final DateTime? lastRewardedAdAt;
  final DateTime? lastInterstitialAdAt;
  final double fatigueScore;
  final bool isPremium;
  final bool hasNoAdsEntitlement;

  bool get isAdFree => isPremium || hasNoAdsEntitlement;
}

final class AdInventorySnapshot {
  const AdInventorySnapshot({
    this.interstitialReady = false,
    this.rewardedReady = false,
    this.rewardedInterstitialReady = false,
    this.nativeReady = false,
    this.appOpenReady = false,
  });

  final bool interstitialReady;
  final bool rewardedReady;
  final bool rewardedInterstitialReady;
  final bool nativeReady;
  final bool appOpenReady;
}

final class MonetizationDecision {
  const MonetizationDecision({
    required this.placement,
    required this.segment,
    required this.score,
    required this.showAd,
    required this.adFormat,
    required this.reason,
    this.skipReason,
    this.cooldownRemaining,
    this.metadata = const <String, Object?>{},
  });

  final MonetizationPlacement placement;
  final MonetizationUserSegment segment;
  final double score;
  final bool showAd;
  final MonetizationAdFormat adFormat;
  final String reason;
  final MonetizationSkipReason? skipReason;
  final Duration? cooldownRemaining;
  final Map<String, Object?> metadata;
}

final class AdShowResult {
  const AdShowResult({
    required this.format,
    required this.outcome,
    this.rewardEarned = false,
    this.errorMessage,
  });

  final MonetizationAdFormat format;
  final MonetizationOutcome outcome;
  final bool rewardEarned;
  final String? errorMessage;
}

final class SegmentThresholds {
  const SegmentThresholds({
    required this.newUserSessions,
    required this.lightUsageScore,
    required this.activeUsageScore,
    required this.heavyUsageScore,
    required this.powerUsageScore,
    required this.highConsumptionApiCallsPerDay,
    required this.highConsumptionApiCallsPerSession,
    required this.expensiveOpsPerDay,
    required this.retryThreshold,
  });

  final int newUserSessions;
  final double lightUsageScore;
  final double activeUsageScore;
  final double heavyUsageScore;
  final double powerUsageScore;
  final int highConsumptionApiCallsPerDay;
  final int highConsumptionApiCallsPerSession;
  final int expensiveOpsPerDay;
  final int retryThreshold;
}

final class MonetizationWeights {
  const MonetizationWeights({
    required this.apiCostWeight,
    required this.saveWeight,
    required this.batchWeight,
    required this.engagementWeight,
    required this.retryWeight,
    required this.failureWeight,
    required this.fatiguePenalty,
    required this.premiumPenalty,
    required this.recentRewardPenalty,
  });

  final double apiCostWeight;
  final double saveWeight;
  final double batchWeight;
  final double engagementWeight;
  final double retryWeight;
  final double failureWeight;
  final double fatiguePenalty;
  final double premiumPenalty;
  final double recentRewardPenalty;
}

final class CappingRules {
  const CappingRules({
    required this.minFullScreenGap,
    required this.minRewardedGap,
    required this.maxFullScreenPerSession,
    required this.maxFullScreenPerDay,
    required this.maxProcessAdsPerSession,
    required this.maxSaveAdsPerSession,
    required this.fatigueScoreLimit,
    required this.recentFullScreenBlockWindow,
    required this.recentRewardBlockWindow,
  });

  final Duration minFullScreenGap;
  final Duration minRewardedGap;
  final int maxFullScreenPerSession;
  final int maxFullScreenPerDay;
  final int maxProcessAdsPerSession;
  final int maxSaveAdsPerSession;
  final double fatigueScoreLimit;
  final Duration recentFullScreenBlockWindow;
  final Duration recentRewardBlockWindow;
}

final class PlacementPolicy {
  const PlacementPolicy({
    required this.enabled,
    required this.defaultFormat,
    required this.rewardedFallbackFormat,
    required this.minScore,
    required this.cooldown,
    this.segmentOverrides = const <MonetizationUserSegment, double>{},
  });

  final bool enabled;
  final MonetizationAdFormat defaultFormat;
  final MonetizationAdFormat rewardedFallbackFormat;
  final double minScore;
  final Duration cooldown;
  final Map<MonetizationUserSegment, double> segmentOverrides;

  double thresholdFor(MonetizationUserSegment segment) {
    return segmentOverrides[segment] ?? minScore;
  }
}

final class MonetizationRemoteConfig {
  const MonetizationRemoteConfig({
    required this.enabled,
    required this.enableInterstitials,
    required this.enableRewarded,
    required this.enableRewardedInterstitials,
    required this.enableNativeAds,
    required this.enableAppOpenAds,
    required this.processMode,
    required this.saveExportMode,
    required this.thresholds,
    required this.weights,
    required this.cappingRules,
    required this.processStartPolicy,
    required this.saveResultPolicy,
    required this.batchOperationPolicy,
    required this.retryPolicy,
    required this.highConsumptionPolicy,
    required this.appOpenPolicy,
    required this.nativePlacementPolicy,
  });

  final bool enabled;
  final bool enableInterstitials;
  final bool enableRewarded;
  final bool enableRewardedInterstitials;
  final bool enableNativeAds;
  final bool enableAppOpenAds;
  final ProcessMonetizationMode processMode;
  final SaveExportMonetizationMode saveExportMode;
  final SegmentThresholds thresholds;
  final MonetizationWeights weights;
  final CappingRules cappingRules;
  final PlacementPolicy processStartPolicy;
  final PlacementPolicy saveResultPolicy;
  final PlacementPolicy batchOperationPolicy;
  final PlacementPolicy retryPolicy;
  final PlacementPolicy highConsumptionPolicy;
  final PlacementPolicy appOpenPolicy;
  final PlacementPolicy nativePlacementPolicy;

  factory MonetizationRemoteConfig.fallback() {
    return MonetizationRemoteConfig.fromJson(
      jsonDecode(_fallbackJson) as Map<String, dynamic>,
    );
  }

  factory MonetizationRemoteConfig.fromJson(Map<String, dynamic> json) {
    Duration readDuration(String key, int fallbackSeconds, Map<String, dynamic> source) {
      final raw = source[key];
      if (raw is num) {
        return Duration(seconds: raw.round());
      }
      return Duration(seconds: fallbackSeconds);
    }

    double readDouble(Map<String, dynamic> source, String key, double fallback) {
      final raw = source[key];
      if (raw is num) {
        return raw.toDouble();
      }
      return fallback;
    }

    int readInt(Map<String, dynamic> source, String key, int fallback) {
      final raw = source[key];
      if (raw is num) {
        return raw.toInt();
      }
      return fallback;
    }

    bool readBool(Map<String, dynamic> source, String key, bool fallback) {
      final raw = source[key];
      if (raw is bool) {
        return raw;
      }
      return fallback;
    }

    MonetizationAdFormat readFormat(Object? raw, MonetizationAdFormat fallback) {
      if (raw is String) {
        return MonetizationAdFormat.values.firstWhere(
          (value) => value.name == raw,
          orElse: () => fallback,
        );
      }
      return fallback;
    }

    Map<MonetizationUserSegment, double> readSegmentOverrides(Object? raw) {
      if (raw is! Map<String, dynamic>) {
        return const <MonetizationUserSegment, double>{};
      }
      return Map<MonetizationUserSegment, double>.fromEntries(
        raw.entries.map(
          (entry) => MapEntry(
            MonetizationUserSegment.values.firstWhere(
              (value) => value.name == entry.key,
              orElse: () => MonetizationUserSegment.lightUser,
            ),
            (entry.value as num).toDouble(),
          ),
        ),
      );
    }

    PlacementPolicy readPlacementPolicy(
      Map<String, dynamic>? source,
      PlacementPolicy fallback,
    ) {
      if (source == null) {
        return fallback;
      }
      return PlacementPolicy(
        enabled: readBool(source, 'enabled', fallback.enabled),
        defaultFormat: readFormat(source['defaultFormat'], fallback.defaultFormat),
        rewardedFallbackFormat: readFormat(
          source['rewardedFallbackFormat'],
          fallback.rewardedFallbackFormat,
        ),
        minScore: readDouble(source, 'minScore', fallback.minScore),
        cooldown: readDuration('cooldownSeconds', fallback.cooldown.inSeconds, source),
        segmentOverrides: readSegmentOverrides(source['segmentOverrides']),
      );
    }

    final thresholdsMap = json['thresholds'] as Map<String, dynamic>? ?? const {};
    final weightsMap = json['weights'] as Map<String, dynamic>? ?? const {};
    final cappingMap = json['cappingRules'] as Map<String, dynamic>? ?? const {};
    final placementsMap = json['placements'] as Map<String, dynamic>? ?? const {};

    return MonetizationRemoteConfig(
      enabled: readBool(json, 'enabled', true),
      enableInterstitials: readBool(json, 'enableInterstitials', true),
      enableRewarded: readBool(json, 'enableRewarded', true),
      enableRewardedInterstitials: readBool(json, 'enableRewardedInterstitials', true),
      enableNativeAds: readBool(json, 'enableNativeAds', true),
      enableAppOpenAds: readBool(json, 'enableAppOpenAds', false),
      processMode: ProcessMonetizationMode.values.firstWhere(
        (value) => value.name == json['processMode'],
        orElse: () => ProcessMonetizationMode.beforeProcess,
      ),
      saveExportMode: SaveExportMonetizationMode.values.firstWhere(
        (value) => value.name == json['saveExportMode'],
        orElse: () => SaveExportMonetizationMode.beforeExport,
      ),
      thresholds: SegmentThresholds(
        newUserSessions: readInt(thresholdsMap, 'newUserSessions', 2),
        lightUsageScore: readDouble(thresholdsMap, 'lightUsageScore', 7),
        activeUsageScore: readDouble(thresholdsMap, 'activeUsageScore', 14),
        heavyUsageScore: readDouble(thresholdsMap, 'heavyUsageScore', 24),
        powerUsageScore: readDouble(thresholdsMap, 'powerUsageScore', 34),
        highConsumptionApiCallsPerDay: readInt(
          thresholdsMap,
          'highConsumptionApiCallsPerDay',
          6,
        ),
        highConsumptionApiCallsPerSession: readInt(
          thresholdsMap,
          'highConsumptionApiCallsPerSession',
          3,
        ),
        expensiveOpsPerDay: readInt(thresholdsMap, 'expensiveOpsPerDay', 4),
        retryThreshold: readInt(thresholdsMap, 'retryThreshold', 2),
      ),
      weights: MonetizationWeights(
        apiCostWeight: readDouble(weightsMap, 'apiCostWeight', 4.0),
        saveWeight: readDouble(weightsMap, 'saveWeight', 2.25),
        batchWeight: readDouble(weightsMap, 'batchWeight', 4.5),
        engagementWeight: readDouble(weightsMap, 'engagementWeight', 0.75),
        retryWeight: readDouble(weightsMap, 'retryWeight', 2.25),
        failureWeight: readDouble(weightsMap, 'failureWeight', 1.5),
        fatiguePenalty: readDouble(weightsMap, 'fatiguePenalty', 2.5),
        premiumPenalty: readDouble(weightsMap, 'premiumPenalty', 200),
        recentRewardPenalty: readDouble(weightsMap, 'recentRewardPenalty', 4.0),
      ),
      cappingRules: CappingRules(
        minFullScreenGap: readDuration('minFullScreenGapSeconds', 90, cappingMap),
        minRewardedGap: readDuration('minRewardedGapSeconds', 180, cappingMap),
        maxFullScreenPerSession: readInt(cappingMap, 'maxFullScreenPerSession', 3),
        maxFullScreenPerDay: readInt(cappingMap, 'maxFullScreenPerDay', 8),
        maxProcessAdsPerSession: readInt(cappingMap, 'maxProcessAdsPerSession', 2),
        maxSaveAdsPerSession: readInt(cappingMap, 'maxSaveAdsPerSession', 2),
        fatigueScoreLimit: readDouble(cappingMap, 'fatigueScoreLimit', 10),
        recentFullScreenBlockWindow: readDuration(
          'recentFullScreenBlockWindowSeconds',
          45,
          cappingMap,
        ),
        recentRewardBlockWindow: readDuration(
          'recentRewardBlockWindowSeconds',
          300,
          cappingMap,
        ),
      ),
      processStartPolicy: readPlacementPolicy(
        placementsMap['processStart'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.interstitial,
          rewardedFallbackFormat: MonetizationAdFormat.rewardedInterstitial,
          minScore: 8,
          cooldown: Duration(seconds: 120),
        ),
      ),
      saveResultPolicy: readPlacementPolicy(
        placementsMap['saveResult'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.interstitial,
          rewardedFallbackFormat: MonetizationAdFormat.rewarded,
          minScore: 10,
          cooldown: Duration(seconds: 150),
        ),
      ),
      batchOperationPolicy: readPlacementPolicy(
        placementsMap['batchOperationStart'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.rewardedInterstitial,
          rewardedFallbackFormat: MonetizationAdFormat.interstitial,
          minScore: 12,
          cooldown: Duration(seconds: 180),
        ),
      ),
      retryPolicy: readPlacementPolicy(
        placementsMap['retryHeavyOperation'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.interstitial,
          rewardedFallbackFormat: MonetizationAdFormat.rewardedInterstitial,
          minScore: 11,
          cooldown: Duration(seconds: 180),
        ),
      ),
      highConsumptionPolicy: readPlacementPolicy(
        placementsMap['freeUserHighConsumption'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.rewardedInterstitial,
          rewardedFallbackFormat: MonetizationAdFormat.interstitial,
          minScore: 14,
          cooldown: Duration(seconds: 180),
        ),
      ),
      appOpenPolicy: readPlacementPolicy(
        placementsMap['appOpen'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: false,
          defaultFormat: MonetizationAdFormat.appOpen,
          rewardedFallbackFormat: MonetizationAdFormat.none,
          minScore: 999,
          cooldown: Duration(minutes: 15),
        ),
      ),
      nativePlacementPolicy: readPlacementPolicy(
        placementsMap['nativeInline'] as Map<String, dynamic>?,
        const PlacementPolicy(
          enabled: true,
          defaultFormat: MonetizationAdFormat.native,
          rewardedFallbackFormat: MonetizationAdFormat.none,
          minScore: 4,
          cooldown: Duration.zero,
        ),
      ),
    );
  }

  static const String _fallbackJson = '''
{"enabled":true,"enableInterstitials":true,"enableRewarded":true,"enableRewardedInterstitials":true,"enableNativeAds":true,"enableAppOpenAds":false,"processMode":"beforeProcess","saveExportMode":"beforeExport","thresholds":{"newUserSessions":2,"lightUsageScore":7,"activeUsageScore":14,"heavyUsageScore":24,"powerUsageScore":34,"highConsumptionApiCallsPerDay":6,"highConsumptionApiCallsPerSession":3,"expensiveOpsPerDay":4,"retryThreshold":2},"weights":{"apiCostWeight":4.0,"saveWeight":2.25,"batchWeight":4.5,"engagementWeight":0.75,"retryWeight":2.25,"failureWeight":1.5,"fatiguePenalty":2.5,"premiumPenalty":200,"recentRewardPenalty":4.0},"cappingRules":{"minFullScreenGapSeconds":90,"minRewardedGapSeconds":180,"maxFullScreenPerSession":3,"maxFullScreenPerDay":8,"maxProcessAdsPerSession":2,"maxSaveAdsPerSession":2,"fatigueScoreLimit":10,"recentFullScreenBlockWindowSeconds":45,"recentRewardBlockWindowSeconds":300},"placements":{"processStart":{"enabled":true,"defaultFormat":"interstitial","rewardedFallbackFormat":"rewardedInterstitial","minScore":8,"cooldownSeconds":120,"segmentOverrides":{"heavyApiConsumer":6,"powerUser":5}},"saveResult":{"enabled":true,"defaultFormat":"interstitial","rewardedFallbackFormat":"rewarded","minScore":10,"cooldownSeconds":150,"segmentOverrides":{"heavyApiConsumer":8,"powerUser":7}},"batchOperationStart":{"enabled":true,"defaultFormat":"rewardedInterstitial","rewardedFallbackFormat":"interstitial","minScore":12,"cooldownSeconds":180},"retryHeavyOperation":{"enabled":true,"defaultFormat":"interstitial","rewardedFallbackFormat":"rewardedInterstitial","minScore":11,"cooldownSeconds":180},"freeUserHighConsumption":{"enabled":true,"defaultFormat":"rewardedInterstitial","rewardedFallbackFormat":"interstitial","minScore":14,"cooldownSeconds":180},"appOpen":{"enabled":false,"defaultFormat":"appOpen","rewardedFallbackFormat":"none","minScore":999,"cooldownSeconds":900},"nativeInline":{"enabled":true,"defaultFormat":"native","rewardedFallbackFormat":"none","minScore":4,"cooldownSeconds":0}}}
''';
}
