import 'package:equatable/equatable.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/secure_signup/domain/entities/restricted_signup_result.dart';

enum RestrictedSignupStatus {
  initial,
  loading,
  success,
  blocked,
  verificationRequired,
  reviewRequested,
  failure,
}

class RestrictedSignupState extends Equatable {
  const RestrictedSignupState({
    this.status = RestrictedSignupStatus.initial,
    this.result,
    this.failure,
    this.userMessage,
  });

  final RestrictedSignupStatus status;
  final RestrictedSignupResult? result;
  final Failure? failure;
  final String? userMessage;

  RestrictedSignupState copyWith({
    RestrictedSignupStatus? status,
    RestrictedSignupResult? result,
    Failure? failure,
    String? userMessage,
  }) {
    return RestrictedSignupState(
      status: status ?? this.status,
      result: result ?? this.result,
      failure: failure ?? this.failure,
      userMessage: userMessage ?? this.userMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, failure, userMessage];
}
