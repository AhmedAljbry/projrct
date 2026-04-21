import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/features/auth/domain/usecases/get_auth_state_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/mark_login_reminder_dismissed_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/sign_out.dart';
import 'package:untitled2/features/auth/domain/usecases/watch_auth_state.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_event.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';

@lazySingleton
class AuthSessionBloc extends Bloc<AuthSessionEvent, AuthSessionState> {
  AuthSessionBloc(
    this._watchAuthState,
    this._signOut,
  ) : super(const AuthSessionUnknown()) {
    on<AuthSessionStarted>(_onStarted);
    on<AuthStateChanged>(_onAuthStateChanged);
    on<AuthSessionFailureReceived>(_onFailureReceived);
    on<AuthSignOutRequested>(_onSignOutRequested);
  }

  final WatchAuthState _watchAuthState;
  final SignOut _signOut;
  StreamSubscription<dynamic>? _subscription;

  Future<void> _onStarted(
    AuthSessionStarted event,
    Emitter<AuthSessionState> emit,
  ) async {
    await _subscription?.cancel();
    final currentStateResult = await getIt<GetAuthStateUseCase>()();
    currentStateResult.fold(
      (failure) => emit(AuthSessionFailure(failure.message)),
      (user) => emit(
        user == null
            ? const AuthSessionGuest()
            : AuthSessionAuthenticated(user),
      ),
    );
    _subscription = _watchAuthState().listen((result) {
      result.fold(
        (failure) => add(AuthSessionFailureReceived(failure.message)),
        (user) => add(AuthStateChanged(user)),
      );
    });
  }

  void _onAuthStateChanged(
    AuthStateChanged event,
    Emitter<AuthSessionState> emit,
  ) {
    final user = event.user;
    if (user == null) {
      emit(const AuthSessionGuest());
      return;
    }
    emit(AuthSessionAuthenticated(user));
  }

  void _onFailureReceived(
    AuthSessionFailureReceived event,
    Emitter<AuthSessionState> emit,
  ) {
    emit(AuthSessionFailure(event.message));
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthSessionState> emit,
  ) async {
    final result = await _signOut();
    await result.fold(
      (_) async {},
      (_) => getIt<MarkLoginReminderDismissedUseCase>()(
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
