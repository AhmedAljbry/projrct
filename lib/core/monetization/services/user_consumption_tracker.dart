import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/monetization/services/premium_access_service.dart';

@lazySingleton
class UserConsumptionTracker {
  UserConsumptionTracker(this._sharedPreferences, this._premiumAccessService);

  static const String _sessionIdKey = 'monetization.session_id';
  static const String _sessionCountKey = 'monetization.total_sessions';
  static const String _dailyKeyPrefix = 'monetization.daily.';
  static const String _sessionMetricsKey = 'monetization.session_metrics';

  final SharedPreferences _sharedPreferences;
  final PremiumAccessService _premiumAccessService;
  final Uuid _uuid = const Uuid();

  String? _sessionId;
  int _sessionDepth = 0;

  Future<void> startSession() async {
    _sessionId = _uuid.v4();
    _sessionDepth = 0;
    await _sharedPreferences.setString(_sessionIdKey, _sessionId!);
    final sessionCount = (_sharedPreferences.getInt(_sessionCountKey) ?? 0) + 1;
    await _sharedPreferences.setInt(_sessionCountKey, sessionCount);
    await _sharedPreferences.setString(
      _sessionMetricsKey,
      jsonEncode(<String, Object?>{
        'full_screen_ads_session': 0,
        'process_ads_session': 0,
        'save_ads_session': 0,
        'api_calls_session': 0,
        'expensive_ops_session': 0,
      }),
    );
  }

  Future<void> recordApiActionStarted(MonetizationOperationContext operation) async {
    _sessionDepth += 1;
    await _updateDaily((data) {
      data['api_calls_today'] = (data['api_calls_today'] as int? ?? 0) + 1;
      if (operation.estimatedApiCostUnits >= 1) {
        data['expensive_ops_today'] = (data['expensive_ops_today'] as int? ?? 0) + 1;
      }
      if (operation.isRetry) {
        data['retry_count_today'] = (data['retry_count_today'] as int? ?? 0) + 1;
      }
    });
    await _updateSession((data) {
      data['api_calls_session'] = (data['api_calls_session'] as int? ?? 0) + 1;
      if (operation.estimatedApiCostUnits >= 1) {
        data['expensive_ops_session'] =
            (data['expensive_ops_session'] as int? ?? 0) + 1;
      }
    });
  }

  Future<void> recordApiActionResult({
    required bool success,
    required bool costlyFailure,
  }) async {
    if (!costlyFailure || success) {
      return;
    }
    await _updateDaily((data) {
      data['failed_costly_attempts_today'] =
          (data['failed_costly_attempts_today'] as int? ?? 0) + 1;
    });
  }

  Future<void> recordSaveExport({
    required int saveIncrement,
    required int exportIncrement,
  }) async {
    await _updateDaily((data) {
      data['save_count_today'] = (data['save_count_today'] as int? ?? 0) + saveIncrement;
      data['export_count_today'] =
          (data['export_count_today'] as int? ?? 0) + exportIncrement;
    });
  }

  Future<void> recordAdShown({
    required MonetizationPlacement placement,
    required MonetizationAdFormat format,
    required bool rewardEarned,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    await _updateDaily((data) {
      data['full_screen_ads_today'] = (data['full_screen_ads_today'] as int? ?? 0) + 1;
      data['last_ad_shown_at'] = nowIso;
      if (format == MonetizationAdFormat.rewarded ||
          format == MonetizationAdFormat.rewardedInterstitial) {
        data['last_rewarded_ad_at'] = nowIso;
      }
      if (format == MonetizationAdFormat.interstitial ||
          format == MonetizationAdFormat.rewardedInterstitial ||
          format == MonetizationAdFormat.appOpen) {
        data['last_interstitial_ad_at'] = nowIso;
      }
      final fatigue = ((data['fatigue_score'] as num?)?.toDouble() ?? 0);
      data['fatigue_score'] = fatigue + (rewardEarned ? 0.5 : 1.0);
    });
    await _updateSession((data) {
      data['full_screen_ads_session'] =
          (data['full_screen_ads_session'] as int? ?? 0) + 1;
      if (placement == MonetizationPlacement.processStart) {
        data['process_ads_session'] = (data['process_ads_session'] as int? ?? 0) + 1;
      }
      if (placement == MonetizationPlacement.saveResult) {
        data['save_ads_session'] = (data['save_ads_session'] as int? ?? 0) + 1;
      }
    });
  }

  Future<void> reduceFatigue() async {
    await _updateDaily((data) {
      final fatigue = ((data['fatigue_score'] as num?)?.toDouble() ?? 0);
      data['fatigue_score'] = fatigue <= 1 ? 0 : fatigue - 1;
    });
  }

  Future<UserConsumptionSnapshot> snapshot() async {
    _sessionId ??= _sharedPreferences.getString(_sessionIdKey);
    if (_sessionId == null) {
      await startSession();
    }
    final daily = _readDaily();
    final session = _readSession();
    return UserConsumptionSnapshot(
      dateKey: _todayKey(),
      sessionId: _sessionId!,
      totalSessions: _sharedPreferences.getInt(_sessionCountKey) ?? 1,
      sessionDepth: _sessionDepth,
      apiCallsToday: daily['api_calls_today'] as int? ?? 0,
      apiCallsThisSession: session['api_calls_session'] as int? ?? 0,
      expensiveOperationsToday: daily['expensive_ops_today'] as int? ?? 0,
      expensiveOperationsThisSession: session['expensive_ops_session'] as int? ?? 0,
      saveCountToday: daily['save_count_today'] as int? ?? 0,
      exportCountToday: daily['export_count_today'] as int? ?? 0,
      retryCountToday: daily['retry_count_today'] as int? ?? 0,
      failedCostlyAttemptsToday: daily['failed_costly_attempts_today'] as int? ?? 0,
      fullScreenAdsSession: session['full_screen_ads_session'] as int? ?? 0,
      fullScreenAdsToday: daily['full_screen_ads_today'] as int? ?? 0,
      processPlacementAdsSession: session['process_ads_session'] as int? ?? 0,
      savePlacementAdsSession: session['save_ads_session'] as int? ?? 0,
      lastAdShownAt: _parseDateTime(daily['last_ad_shown_at']),
      lastRewardedAdAt: _parseDateTime(daily['last_rewarded_ad_at']),
      lastInterstitialAdAt: _parseDateTime(daily['last_interstitial_ad_at']),
      fatigueScore: ((daily['fatigue_score'] as num?)?.toDouble() ?? 0),
      isPremium: _premiumAccessService.isPremiumUser,
      hasNoAdsEntitlement: _premiumAccessService.hasNoAdsEntitlement,
    );
  }

  Map<String, Object?> _readDaily() {
    final raw = _sharedPreferences.getString('$_dailyKeyPrefix${_todayKey()}');
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }
    return Map<String, Object?>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  Map<String, Object?> _readSession() {
    final raw = _sharedPreferences.getString(_sessionMetricsKey);
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }
    return Map<String, Object?>.from(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _updateDaily(void Function(Map<String, Object?> data) mutate) async {
    final data = _readDaily();
    mutate(data);
    await _sharedPreferences.setString(
      '$_dailyKeyPrefix${_todayKey()}',
      jsonEncode(data),
    );
  }

  Future<void> _updateSession(void Function(Map<String, Object?> data) mutate) async {
    final data = _readSession();
    mutate(data);
    await _sharedPreferences.setString(_sessionMetricsKey, jsonEncode(data));
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  DateTime? _parseDateTime(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw);
  }
}
