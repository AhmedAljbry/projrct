class Failure {
  const Failure(
    this.message, {
    required this.code,
    this.isRetryable = false,
    this.meta = const <String, dynamic>{},
  });

  final String message;
  final String code;
  final bool isRetryable;
  final Map<String, dynamic> meta;

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}
