import 'package:equatable/equatable.dart';

class RestrictedSignupResult extends Equatable {
  const RestrictedSignupResult({
    required this.accountId,
    required this.decision,
    required this.message,
    required this.reviewRequested,
  });

  final String accountId;
  final String decision;
  final String message;
  final bool reviewRequested;

  bool get requiresReview => decision == 'REQUIRE_VERIFICATION';

  @override
  List<Object?> get props => [accountId, decision, message, reviewRequested];
}
