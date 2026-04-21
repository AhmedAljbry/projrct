import 'package:untitled2/features/auth/domain/entities/auth_user.dart';

sealed class AuthSessionState {
  const AuthSessionState();
}

class AuthSessionUnknown extends AuthSessionState {
  const AuthSessionUnknown();
}

class AuthSessionGuest extends AuthSessionState {
  const AuthSessionGuest();
}

class AuthSessionAuthenticated extends AuthSessionState {
  const AuthSessionAuthenticated(this.user);

  final AuthUser user;
}

class AuthSessionFailure extends AuthSessionState {
  const AuthSessionFailure(this.message);

  final String message;
}
