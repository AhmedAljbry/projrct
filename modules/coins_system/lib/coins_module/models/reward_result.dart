class RewardResult {
  const RewardResult({
    required this.success,
    required this.coinsAdded,
    required this.balance,
    required this.message,
  });

  final bool success;
  final int coinsAdded;
  final int balance;
  final String message;

  factory RewardResult.safe([String message = 'Unavailable']) => RewardResult(
        success: false,
        coinsAdded: 0,
        balance: 0,
        message: message,
      );
}
