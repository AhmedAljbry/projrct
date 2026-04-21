class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.isEmailVerified,
    this.displayName,
    this.photoUrl,
  });

  final String id;
  final String email;
  final bool isEmailVerified;
  final String? displayName;
  final String? photoUrl;
}
