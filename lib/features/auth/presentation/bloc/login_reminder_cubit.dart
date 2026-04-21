import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/features/auth/domain/usecases/mark_login_reminder_dismissed_use_case.dart';
import 'package:untitled2/features/auth/domain/usecases/should_show_login_reminder_use_case.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/bloc/login_reminder_state.dart';

class LoginReminderCubit extends Cubit<LoginReminderState> {
  LoginReminderCubit(
    this._shouldShowLoginReminder,
    this._markLoginReminderDismissed,
    this._talker,
  ) : super(const LoginReminderHidden());

  static const Duration initialGuestGracePeriod = Duration(seconds: 6);

  final ShouldShowLoginReminderUseCase _shouldShowLoginReminder;
  final MarkLoginReminderDismissedUseCase _markLoginReminderDismissed;
  final Talker _talker;

  Timer? _graceTimer;

  Future<void> handleAuthState(AuthSessionState state) async {
    _graceTimer?.cancel();

    if (state is AuthSessionAuthenticated) {
      emit(const LoginReminderHidden());
      return;
    }

    if (state is AuthSessionUnknown) {
      return;
    }

    final result = await _shouldShowLoginReminder();
    result.fold(
      (failure) {
        _talker.warning(
          'Unable to evaluate login reminder visibility: ${failure.message}',
        );
        emit(const LoginReminderHidden());
      },
      (shouldShow) {
        if (!shouldShow) {
          emit(const LoginReminderHidden());
          return;
        }
        _graceTimer = Timer(initialGuestGracePeriod, () {
          emit(const LoginReminderVisible());
        });
      },
    );
  }

  Future<void> dismissReminder() async {
    _graceTimer?.cancel();
    final result = await _markLoginReminderDismissed(timestamp: DateTime.now());
    result.fold(
      (failure) => _talker.warning(
        'Unable to persist login reminder dismissal: ${failure.message}',
      ),
      (_) => _talker.debug('Login reminder dismissed'),
    );
    emit(const LoginReminderHidden());
  }

  void hideReminder() {
    _graceTimer?.cancel();
    emit(const LoginReminderHidden());
  }

  @override
  Future<void> close() async {
    _graceTimer?.cancel();
    return super.close();
  }
}
