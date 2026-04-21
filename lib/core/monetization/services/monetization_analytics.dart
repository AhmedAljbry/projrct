import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';

@lazySingleton
class MonetizationAnalytics {
  MonetizationAnalytics(this._analytics, this._talker);

  final AppAnalytics _analytics;
  final Talker _talker;

  Future<void> logDecision({
    required MonetizationDecision decision,
    required MonetizationOperationContext operation,
  }) async {
    await _log(
      'monetization_ad_decision',
      <String, Object?>{
        'placement': decision.placement.name,
        'segment': decision.segment.name,
        'score': decision.score.round(),
        'show_ad': decision.showAd,
        'format': decision.adFormat.name,
        'reason': decision.reason,
        'skip_reason': decision.skipReason?.name,
        'operation_type': operation.operationType,
      },
    );
  }

  Future<void> logAdLifecycle({
    required String phase,
    required MonetizationPlacement placement,
    required MonetizationAdFormat format,
    String? errorMessage,
  }) async {
    await _log(
      'monetization_ad_$phase',
      <String, Object?>{
        'placement': placement.name,
        'format': format.name,
        'error_message': errorMessage,
      },
    );
  }

  Future<void> logApiAction({
    required String phase,
    required MonetizationOperationContext operation,
    String? result,
  }) async {
    await _log(
      'monetization_api_action_$phase',
      <String, Object?>{
        'operation_id': operation.operationId,
        'operation_type': operation.operationType,
        'estimated_cost_units': operation.estimatedApiCostUnits,
        'is_batch': operation.isBatch,
        'is_retry': operation.isRetry,
        'result': result,
      },
    );
  }

  Future<void> logSaveExport({
    required String phase,
    required MonetizationOperationContext operation,
    required bool success,
  }) async {
    await _log(
      'monetization_save_export_$phase',
      <String, Object?>{
        'operation_id': operation.operationId,
        'operation_type': operation.operationType,
        'success': success,
      },
    );
  }

  Future<void> logFunnel({
    required String step,
    required MonetizationOperationContext operation,
    MonetizationDecision? decision,
  }) async {
    await _log(
      'monetization_funnel',
      <String, Object?>{
        'step': step,
        'operation_id': operation.operationId,
        'operation_type': operation.operationType,
        'placement': decision?.placement.name,
        'format': decision?.adFormat.name,
      },
    );
  }

  Future<void> _log(String name, Map<String, Object?> parameters) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (error, stackTrace) {
      _talker.warning('Monetization analytics failed: $name', error, stackTrace);
    }
  }
}
