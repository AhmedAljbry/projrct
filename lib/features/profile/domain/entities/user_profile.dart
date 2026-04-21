class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.photoUrl,
    this.fcmToken,
  });

  final String id;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? displayName;
  final String? photoUrl;
  final String? fcmToken;
}
