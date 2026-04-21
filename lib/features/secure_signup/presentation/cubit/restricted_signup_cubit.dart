import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/error/failure.dart';
import 'package:untitled2/features/secure_signup/domain/usecases/create_restricted_account_use_case.dart';
import 'package:untitled2/features/secure_signup/domain/usecases/request_signup_override_use_case.dart';
import 'package:untitled2/features/secure_signup/presentation/cubit/restricted_signup_state.dart';

class RestrictedSignupCubit extends Cubit<RestrictedSignupState> {
  RestrictedSignupCubit({
    required CreateRestrictedAccountUseCase createRestrictedAccountUseCase,
    required RequestSignupOverrideUseCase requestSignupOverrideUseCase,
  })  : _createRestrictedAccountUseCase = createRestrictedAccountUseCase,
        _requestSignupOverrideUseCase = requestSignupOverrideUseCase,
        super(const RestrictedSignupState());

  final CreateRestrictedAccountUseCase _createRestrictedAccountUseCase;
  final RequestSignupOverrideUseCase _requestSignupOverrideUseCase;

  Future<void> submit({
    required String email,
    required String password,
    required String displayName,
  }) async {
    emit(const RestrictedSignupState(status: RestrictedSignupStatus.loading));
    final result = await _createRestrictedAccountUseCase(
      email: email,
      password: password,
      displayName: displayName,
    );

    result.fold(
      (failure) => emit(
        RestrictedSignupState(
          status: _statusFromFailure(failure),
          failure: failure,
          userMessage: failure.message,
        ),
      ),
      (success) => emit(
        RestrictedSignupState(
          status: success.requiresReview
              ? RestrictedSignupStatus.verificationRequired
              : RestrictedSignupStatus.success,
          result: success,
          userMessage: success.message,
        ),
      ),
    );
  }

  Future<void> requestReview({required String reason}) async {
    emit(
      state.copyWith(
        status: RestrictedSignupStatus.loading,
        userMessage: 'Submitting your device review request...',
      ),
    );
    final result = await _requestSignupOverrideUseCase(reason: reason);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: RestrictedSignupStatus.failure,
          failure: failure,
          userMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: RestrictedSignupStatus.reviewRequested,
          userMessage:
              'Your request has been queued for manual review by support.',
        ),
      ),
    );
  }

  RestrictedSignupStatus _statusFromFailure(Failure failure) {
    if (failure is DeviceAlreadyUsedFailure) {
      return RestrictedSignupStatus.blocked;
    }
    if (failure is VerificationRequiredFailure) {
      return RestrictedSignupStatus.verificationRequired;
    }
    return RestrictedSignupStatus.failure;
  }
}
