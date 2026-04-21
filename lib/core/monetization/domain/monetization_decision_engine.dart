import 'package:injectable/injectable.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';

@lazySingleton
class MonetizationDecisionEngine {
  const MonetizationDecisionEngine();

  MonetizationDecision evaluate({
    required MonetizationPlacement placement,
    required MonetizationRemoteConfig config,
    required UserConsumptionSnapshot snapshot,
    required MonetizationOperationContext operation,
    required MonetizationUiState uiState,
    required AdInventorySnapshot inventory,
    required DateTime now,
  }) {
    // Global and entitlement guards should exit early so premium users never enter ad logic.
    if (!config.enabled) {
      return _skip(
        placement,
        MonetizationUserSegment.lightUser,
        0,
        'Monetization disabled globally',
        MonetizationSkipReason.disabled,
      );
    }
    if (snapshot.isAdFree) {
      return _skip(
        placement,
        MonetizationUserSegment.premium,
        0,
        'Premium or no-ads user bypassed',
        MonetizationSkipReason.premium,
      );
    }
    if (!uiState.isForeground || uiState.isOffline) {
      return _skip(
        placement,
        MonetizationUserSegment.lightUser,
        0,
        uiState.isOffline ? 'Offline flow bypassed' : 'Background flow bypassed',
        MonetizationSkipReason.noInternet,
      );
    }
    if (uiState.isEditingGestureActive || !uiState.allowFullScreenAds) {
      // Editing gestures are protected because mid-gesture ads increase accidental-click risk.
      return _skip(
        placement,
        MonetizationUserSegment.cooldownProtected,
        0,
        'Ad blocked during active editing or another fullscreen ad',
        MonetizationSkipReason.activeGesture,
      );
    }
    if (operation.isCriticalFlow || operation.requiresImmediateExecution) {
      // Expensive flows may still skip ads when user intent is urgent or recovery-sensitive.
      return _skip(
        placement,
        MonetizationUserSegment.cooldownProtected,
        0,
        'Critical flow protected from interruption',
        MonetizationSkipReason.criticalFlow,
      );
    }

    final score = _score(config.weights, snapshot, operation, now);
    final segment = _classifySegment(snapshot, score, config.thresholds);
    final policy = _policyFor(placement, config);

    if (!policy.enabled) {
      return _skip(
        placement,
        segment,
        score,
        'Placement disabled by remote config',
        MonetizationSkipReason.disabled,
      );
    }
    if (_isSessionCapped(placement, snapshot, config.cappingRules)) {
      return _skip(
        placement,
        segment,
        score,
        'Session capping reached for placement',
        MonetizationSkipReason.sessionCap,
      );
    }
    if (snapshot.fatigueScore >= config.cappingRules.fatigueScoreLimit) {
      // Fatigue is a hard brake to avoid short-term revenue gains hurting retention.
      return _skip(
        placement,
        MonetizationUserSegment.cooldownProtected,
        score,
        'Fatigue protection applied',
        MonetizationSkipReason.fatigue,
      );
    }

    final cooldownRemaining = _cooldownRemaining(
      placement: placement,
      policy: policy,
      snapshot: snapshot,
      rules: config.cappingRules,
      now: now,
    );
    if (cooldownRemaining != null && cooldownRemaining > Duration.zero) {
      return MonetizationDecision(
        placement: placement,
        segment: segment,
        score: score,
        showAd: false,
        adFormat: MonetizationAdFormat.none,
        reason: 'Cooldown active',
        skipReason: MonetizationSkipReason.cooldown,
        cooldownRemaining: cooldownRemaining,
      );
    }
    if (score < policy.thresholdFor(segment)) {
      return _skip(
        placement,
        segment,
        score,
        'Score below threshold for placement',
        MonetizationSkipReason.lowPriority,
      );
    }

    final preferredFormat = _preferredFormat(
      placement: placement,
      config: config,
      policy: policy,
      segment: segment,
      operation: operation,
    );
    final resolvedFormat = _resolveInventory(
      preferredFormat: preferredFormat,
      fallbackFormat: policy.rewardedFallbackFormat,
      inventory: inventory,
      config: config,
      allowNativeAds: uiState.allowNativeAds,
    );
    if (resolvedFormat == MonetizationAdFormat.none) {
      return _skip(
        placement,
        segment,
        score,
        'No ad inventory is ready',
        MonetizationSkipReason.noInventory,
      );
    }

    return MonetizationDecision(
      placement: placement,
      segment: segment,
      score: score,
      showAd: true,
      adFormat: resolvedFormat,
      reason: 'Placement eligible by policy, score, UX guard, and inventory',
      metadata: <String, Object?>{
        'preferred_format': preferredFormat.name,
        'resolved_format': resolvedFormat.name,
        'operation_type': operation.operationType,
      },
    );
  }

  double _score(
    MonetizationWeights weights,
    UserConsumptionSnapshot snapshot,
    MonetizationOperationContext operation,
    DateTime now,
  ) {
    final recentRewardPenalty = snapshot.lastRewardedAdAt == null
        ? 0.0
        : now.difference(snapshot.lastRewardedAdAt!).inMinutes < 15
            ? weights.recentRewardPenalty
            : 0.0;

    return (weights.apiCostWeight * operation.estimatedApiCostUnits) +
        (weights.saveWeight *
            (snapshot.saveCountToday +
                operation.saveCountIncrement +
                operation.exportCountIncrement)) +
        (weights.batchWeight * (operation.isBatch ? 1.0 : 0.0)) +
        (weights.engagementWeight * (snapshot.sessionDepth + operation.sessionDepth)) +
        (weights.retryWeight * (operation.isRetry ? 1.0 : 0.0)) +
        (weights.failureWeight * snapshot.failedCostlyAttemptsToday) -
        (weights.fatiguePenalty * snapshot.fatigueScore) -
        (snapshot.isPremium ? weights.premiumPenalty : 0.0) -
        recentRewardPenalty;
  }

  MonetizationUserSegment _classifySegment(
    UserConsumptionSnapshot snapshot,
    double score,
    SegmentThresholds thresholds,
  ) {
    if (snapshot.isAdFree) {
      return MonetizationUserSegment.premium;
    }
    if (snapshot.totalSessions <= thresholds.newUserSessions) {
      return MonetizationUserSegment.newUser;
    }
    if (score >= thresholds.powerUsageScore ||
        snapshot.apiCallsToday >= thresholds.highConsumptionApiCallsPerDay * 2) {
      return MonetizationUserSegment.powerUser;
    }
    if (score >= thresholds.heavyUsageScore ||
        snapshot.apiCallsToday >= thresholds.highConsumptionApiCallsPerDay ||
        snapshot.apiCallsThisSession >= thresholds.highConsumptionApiCallsPerSession ||
        snapshot.expensiveOperationsToday >= thresholds.expensiveOpsPerDay) {
      return MonetizationUserSegment.heavyApiConsumer;
    }
    if (score >= thresholds.activeUsageScore) {
      return MonetizationUserSegment.activeUser;
    }
    return score <= thresholds.lightUsageScore
        ? MonetizationUserSegment.lightUser
        : MonetizationUserSegment.activeUser;
  }

  PlacementPolicy _policyFor(
    MonetizationPlacement placement,
    MonetizationRemoteConfig config,
  ) {
    return switch (placement) {
      MonetizationPlacement.processStart => config.processStartPolicy,
      MonetizationPlacement.saveResult => config.saveResultPolicy,
      MonetizationPlacement.batchOperationStart => config.batchOperationPolicy,
      MonetizationPlacement.retryHeavyOperation => config.retryPolicy,
      MonetizationPlacement.freeUserHighConsumption => config.highConsumptionPolicy,
      MonetizationPlacement.appOpen => config.appOpenPolicy,
    };
  }

  bool _isSessionCapped(
    MonetizationPlacement placement,
    UserConsumptionSnapshot snapshot,
    CappingRules rules,
  ) {
    if (snapshot.fullScreenAdsSession >= rules.maxFullScreenPerSession ||
        snapshot.fullScreenAdsToday >= rules.maxFullScreenPerDay) {
      return true;
    }
    return switch (placement) {
      MonetizationPlacement.processStart =>
        snapshot.processPlacementAdsSession >= rules.maxProcessAdsPerSession,
      MonetizationPlacement.saveResult =>
        snapshot.savePlacementAdsSession >= rules.maxSaveAdsPerSession,
      _ => false,
    };
  }

  Duration? _cooldownRemaining({
    required MonetizationPlacement placement,
    required PlacementPolicy policy,
    required UserConsumptionSnapshot snapshot,
    required CappingRules rules,
    required DateTime now,
  }) {
    final lastShown = snapshot.lastAdShownAt;
    if (lastShown != null) {
      final sinceLastAd = now.difference(lastShown);
      final fullScreenGap =
          policy.cooldown > rules.minFullScreenGap ? policy.cooldown : rules.minFullScreenGap;
      if (sinceLastAd < fullScreenGap) {
        return fullScreenGap - sinceLastAd;
      }
    }

    final lastInterstitial = snapshot.lastInterstitialAdAt;
    if (lastInterstitial != null &&
        now.difference(lastInterstitial) < rules.recentFullScreenBlockWindow) {
      return rules.recentFullScreenBlockWindow - now.difference(lastInterstitial);
    }

    if (placement == MonetizationPlacement.processStart ||
        placement == MonetizationPlacement.batchOperationStart ||
        placement == MonetizationPlacement.retryHeavyOperation) {
      final lastRewarded = snapshot.lastRewardedAdAt;
      if (lastRewarded != null &&
          now.difference(lastRewarded) < rules.recentRewardBlockWindow) {
        return rules.recentRewardBlockWindow - now.difference(lastRewarded);
      }
    }
    return null;
  }

  MonetizationAdFormat _preferredFormat({
    required MonetizationPlacement placement,
    required MonetizationRemoteConfig config,
    required PlacementPolicy policy,
    required MonetizationUserSegment segment,
    required MonetizationOperationContext operation,
  }) {
    if (placement == MonetizationPlacement.appOpen) {
      return MonetizationAdFormat.appOpen;
    }
    if (placement == MonetizationPlacement.saveResult &&
        config.saveExportMode == SaveExportMonetizationMode.rewardedUpsell &&
        operation.allowRewardedUpsell &&
        config.enableRewarded) {
      return MonetizationAdFormat.rewarded;
    }
    if (placement == MonetizationPlacement.batchOperationStart ||
        segment == MonetizationUserSegment.powerUser) {
      if (config.enableRewardedInterstitials) {
        return MonetizationAdFormat.rewardedInterstitial;
      }
    }
    return policy.defaultFormat;
  }

  MonetizationAdFormat _resolveInventory({
    required MonetizationAdFormat preferredFormat,
    required MonetizationAdFormat fallbackFormat,
    required AdInventorySnapshot inventory,
    required MonetizationRemoteConfig config,
    required bool allowNativeAds,
  }) {
    bool isReady(MonetizationAdFormat format) {
      return switch (format) {
        MonetizationAdFormat.interstitial =>
          config.enableInterstitials && inventory.interstitialReady,
        MonetizationAdFormat.rewarded =>
          config.enableRewarded && inventory.rewardedReady,
        MonetizationAdFormat.rewardedInterstitial =>
          config.enableRewardedInterstitials && inventory.rewardedInterstitialReady,
        MonetizationAdFormat.native =>
          allowNativeAds && config.enableNativeAds && inventory.nativeReady,
        MonetizationAdFormat.appOpen =>
          config.enableAppOpenAds && inventory.appOpenReady,
        MonetizationAdFormat.none => false,
      };
    }

    if (isReady(preferredFormat)) {
      return preferredFormat;
    }
    if (isReady(fallbackFormat)) {
      return fallbackFormat;
    }
    if (preferredFormat != MonetizationAdFormat.interstitial &&
        isReady(MonetizationAdFormat.interstitial)) {
      return MonetizationAdFormat.interstitial;
    }
    return MonetizationAdFormat.none;
  }

  MonetizationDecision _skip(
    MonetizationPlacement placement,
    MonetizationUserSegment segment,
    double score,
    String reason,
    MonetizationSkipReason skipReason,
  ) {
    return MonetizationDecision(
      placement: placement,
      segment: segment,
      score: score,
      showAd: false,
      adFormat: MonetizationAdFormat.none,
      reason: reason,
      skipReason: skipReason,
    );
  }
}
