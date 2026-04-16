class CoinTransaction {
  const CoinTransaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String userId;
  final String type;
  final int amount;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  factory CoinTransaction.fromMap(String id, Map<String, dynamic>? map) {
    final data = map ?? <String, dynamic>{};
    return CoinTransaction(
      id: id,
      userId: data['userId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'unknown',
      amount: (data['amount'] as num?)?.toInt() ?? 0,
      createdAt: _parseDate(data['createdAt']),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? const {}),
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
