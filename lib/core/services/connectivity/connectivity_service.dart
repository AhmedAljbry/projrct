import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

import 'connectivity_state.dart';

@lazySingleton
class ConnectivityService {
  ConnectivityService(this._connectivity, this._talker);

  final Connectivity _connectivity;
  final Talker _talker;

  final StreamController<ConnectivityState> _controller =
      StreamController<ConnectivityState>.broadcast();

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  ConnectivityState _currentState = const ConnectivityState.initial();

  ConnectivityState get currentState => _currentState;
  Stream<ConnectivityState> get states => _controller.stream;

  Future<void> initialize() async {
    if (_subscription != null) {
      return;
    }
    try {
      final results = await _connectivity.checkConnectivity();
      _emit(_map(results));
      _subscription = _connectivity.onConnectivityChanged.listen(
        (results) => _emit(_map(results)),
        onError: (Object error, StackTrace stackTrace) {
          _talker.warning('Connectivity listener failed', error, stackTrace);
        },
      );
    } catch (error, stackTrace) {
      _talker.warning('Connectivity initialization failed', error, stackTrace);
    }
  }

  Future<bool> isOnline() async {
    final results = await _connectivity.checkConnectivity();
    final state = _map(results);
    _emit(state);
    return state.isOnline;
  }

  ConnectivityState _map(List<ConnectivityResult> results) {
    final hasConnectionType = results.any(
      (result) => result != ConnectivityResult.none,
    );
    return _currentState.copyWith(
      isOnline: hasConnectionType,
      hasConnectionType: hasConnectionType,
    );
  }

  void _emit(ConnectivityState state) {
    if (_currentState == state) {
      return;
    }
    _currentState = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }
}
