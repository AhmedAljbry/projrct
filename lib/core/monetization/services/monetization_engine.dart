import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/monetization/domain/monetization_decision_engine.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/monetization/services/ad_inventory_manager.dart';
import 'package:untitled2/core/monetization/services/monetization_analytics.dart';
import 'package:untitled2/core/monetization/services/monetization_remote_config_service.dart';
import 'package:untitled2/core/monetization/services/user_consumption_tracker.dart';

@lazySingleton
class MonetizationEngine {
  MonetizationEngine(
    this._decisionEngine,
    this._adInventoryManager,
    this._remoteConfigService,
    this._analytics,
    this._userConsumptionTracker,
    this._connectivity,
    this._talker,
  );

  final MonetizationDecisionEngine _decisionEngine;
  final AdInventoryManager _adInventoryManager;
  final MonetizationRemoteConfigService _remoteConfigService;
  final MonetizationAnalytics _analytics;
  final UserConsumptionTracker _userConsumptionTracker;
  final Connectivity _connectivity;
  final Talker _talker;

  Future<void> initialize() async {
    await _userConsumptionTracker.startSession();
    await _adInventoryManager.initialize();
    await _adInventoryManager.preloadEligibleAds(_remoteConfigService.current);
  }

  Future<MonetizationDecision> guardPlacement({
    required MonetizationPlacement placement,
    required MonetizationOperationContext operation,
    required MonetizationUiState uiState,
  }) async {
    final config = _remoteConfigService.current;
    final snapshot = await _userConsumptionTracker.snapshot();
    final connectivityResult = await _connectivity.checkConnectivity();
    final resolvedUiState = MonetizationUiState(
      routeName: uiState.routeName,
      isEditingGestureActive: uiState.isEditingGestureActive,
      isOffline:
          uiState.isOffline || connectivityResult.contains(ConnectivityResult.none),
      isForeground: uiState.isForeground,
      allowFullScreenAds: uiState.allowFullScreenAds &&
          !_adInventoryManager.isShowingFullScreen,
      allowNativeAds: uiState.allowNativeAds,
    );
    final decision = _decisionEngine.evaluate(
      placement: placement,
      config: config,
      snapshot: snapshot,
      operation: operation,
      uiState: resolvedUiState,
      inventory: _adInventoryManager.inventorySnapshot,
      now: DateTime.now(),
    );
    await _analytics.logDecision(decision: decision, operation: operation);
    return decision;
  }

  Future<AdShowResult> maybeShow({
    required MonetizationDecision decision,
    required MonetizationOperationContext operation,
  }) async {
    if (!decision.showAd) {
      await _analytics.logAdLifecycle(
        phase: 'skipped',
        placement: decision.placement,
        format: decision.adFormat,
        errorMessage: decision.skipReason?.name,
      );
      return const AdShowResult(
        format: MonetizationAdFormat.none,
        outcome: MonetizationOutcome.skipped,
      );
    }

    final result = await _adInventoryManager.show(
      decision.adFormat,
      decision.placement,
    );
    if (result.outcome == MonetizationOutcome.dismissed ||
        result.outcome == MonetizationOutcome.rewarded) {
      await _userConsumptionTracker.recordAdShown(
        placement: decision.placement,
        format: result.format,
        rewardEarned: result.rewardEarned,
      );
    } else if (result.outcome == MonetizationOutcome.unavailable ||
        result.outcome == MonetizationOutcome.skipped) {
      await _userConsumptionTracker.reduceFatigue();
    }

    await _analytics.logAdLifecycle(
      phase: result.outcome.name,
      placement: decision.placement,
      format: result.format,
      errorMessage: result.errorMessage,
    );
    await safePreload();
    return result;
  }

  Future<void> trackApiStarted(MonetizationOperationContext operation) async {
    await _userConsumptionTracker.recordApiActionStarted(operation);
    await _analytics.logApiAction(phase: 'started', operation: operation);
    await _analytics.logFunnel(step: 'api_action_started', operation: operation);
  }

  Future<void> trackApiCompleted({
    required MonetizationOperationContext operation,
    required bool success,
    required bool costlyFailure,
  }) async {
    await _userConsumptionTracker.recordApiActionResult(
      success: success,
      costlyFailure: costlyFailure,
    );
    await _analytics.logApiAction(
      phase: success ? 'completed' : 'failed',
      operation: operation,
      result: success ? 'success' : 'failure',
    );
    await _analytics.logFunnel(
      step: success ? 'api_action_completed' : 'api_action_failed',
      operation: operation,
    );
  }

  Future<void> trackSaveExportCompleted({
    required MonetizationOperationContext operation,
    required bool success,
  }) async {
    await _userConsumptionTracker.recordSaveExport(
      saveIncrement: operation.saveCountIncrement,
      exportIncrement: operation.exportCountIncrement,
    );
    await _analytics.logSaveExport(
      phase: success ? 'completed' : 'failed',
      operation: operation,
      success: success,
    );
    await _analytics.logFunnel(
      step: success ? 'save_export_completed' : 'save_export_failed',
      operation: operation,
    );
  }

  Future<void> safePreload() async {
    try {
      await _adInventoryManager.preloadEligibleAds(_remoteConfigService.current);
    } catch (error, stackTrace) {
      _talker.warning('Monetization preload failed', error, stackTrace);
    }
  }

  AdInventoryManager get adInventoryManager => _adInventoryManager;

  MonetizationRemoteConfigService get remoteConfigService => _remoteConfigService;
}
