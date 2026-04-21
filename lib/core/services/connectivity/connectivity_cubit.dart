import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';

import 'connectivity_service.dart';
import 'connectivity_state.dart';

@lazySingleton
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._service, this._analytics)
      : super(_service.currentState) {
    _subscription = _service.states.listen(_onConnectivityChanged);
  }

  final ConnectivityService _service;
  final AppAnalytics _analytics;

  StreamSubscription<ConnectivityState>? _subscription;

  Future<void> refresh() async {
    final isOnline = await _service.isOnline();
    emit(state.copyWith(isOnline: isOnline, hasConnectionType: isOnline));
  }

  Future<bool> canUseNetworkAction() async {
    final online = await _service.isOnline();
    if (!online && !state.hasShownOfflineEvent) {
      await _analytics.log(
        AppAnalyticsEvent.offlineStateSeen(source: 'network_action'),
      );
      emit(state.copyWith(hasShownOfflineEvent: true));
    }
    return online;
  }

  void _onConnectivityChanged(ConnectivityState connectivityState) {
    final wasOffline = !state.isOnline;
    final shouldTrackOffline = !connectivityState.isOnline && !state.hasShownOfflineEvent;
    emit(
      connectivityState.copyWith(
        hasShownOfflineEvent: connectivityState.isOnline
            ? false
            : (shouldTrackOffline ? true : state.hasShownOfflineEvent),
      ),
    );
    if (shouldTrackOffline) {
      _analytics.log(AppAnalyticsEvent.offlineStateSeen(source: 'global'));
    }
    if (wasOffline && connectivityState.isOnline) {
      emit(connectivityState.copyWith(hasShownOfflineEvent: false));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
