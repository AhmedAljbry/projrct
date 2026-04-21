import 'package:untitled2/features/auth/domain/entities/auth_user.dart';

sealed class AuthSessionEvent {
  const AuthSessionEvent();
}

class AuthSessionStarted extends AuthSessionEvent {
  const AuthSessionStarted();
}

class AuthStateChanged extends AuthSessionEvent {
  const AuthStateChanged(this.user);

  final AuthUser? user;
}

class AuthSessionFailureReceived extends AuthSessionEvent {
  const AuthSessionFailureReceived(this.message);

  final String message;
}

class AuthSignOutRequested extends AuthSessionEvent {
  const AuthSignOutRequested();
}
