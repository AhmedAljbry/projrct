import 'package:equatable/equatable.dart';

import 'package:untitled2/features/secure_signup/domain/entities/restricted_signup_result.dart';

class RestrictedSignupApiResponse extends Equatable {
  const RestrictedSignupApiResponse({
    required this.accountId,
    required this.decision,
    required this.message,
    required this.reviewRequested,
  });

  final String accountId;
  final String decision;
  final String message;
  final bool reviewRequested;

  factory RestrictedSignupApiResponse.fromJson(Map<String, dynamic> json) {
    return RestrictedSignupApiResponse(
      accountId: json['account_id'] as String? ?? '',
      decision: json['decision'] as String? ?? 'ALLOW',
      message: json['message'] as String? ?? '',
      reviewRequested: json['review_requested'] as bool? ?? false,
    );
  }

  RestrictedSignupResult toDomain() => RestrictedSignupResult(
        accountId: accountId,
        decision: decision,
        message: message,
        reviewRequested: reviewRequested,
      );

  @override
  List<Object?> get props => [accountId, decision, message, reviewRequested];
}
