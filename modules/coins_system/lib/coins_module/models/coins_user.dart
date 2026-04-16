class CoinsUser {
  const CoinsUser({
    required this.userId,
    required this.coins,
    required this.createdAt,
    required this.deviceHash,
    required this.fingerprintSignature,
  });

  final String userId;
  final int coins;
  final DateTime createdAt;
  final String deviceHash;
  final String fingerprintSignature;

  factory CoinsUser.empty() => CoinsUser(
        userId: '',
        coins: 0,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        deviceHash: '',
        fingerprintSignature: '',
      );

  factory CoinsUser.fromMap(String userId, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return CoinsUser(
      userId: userId,
      coins: (data['coins'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(data['createdAt']),
      deviceHash: data['deviceHash']?.toString() ?? '',
      fingerprintSignature: data['fingerprintSignature']?.toString() ?? '',
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value != null && value.runtimeType.toString() == 'Timestamp') {
      return value.toDate() as DateTime;
    }
    return DateTime.now();
  }
}
