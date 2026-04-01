import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/coins_failures.dart';
import '../../core/error/failure.dart';
import '../../domain/entities/coins_models.dart';
import '../../domain/repositories/coins_repository.dart';
import '../remote/coins_remote_data_source.dart';

@LazySingleton(as: CoinsRepository)
class CoinsRepositoryImpl implements CoinsRepository {
  CoinsRepositoryImpl(this._remoteDataSource);

  final CoinsRemoteDataSource _remoteDataSource;

  @override
  Future<Either<Failure, WalletOverview>> getWalletOverview(String userId) async {
    try {
      final response = await _remoteDataSource.getWalletOverview(userId);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, TransactionPage>> getTransactionHistory(
    TransactionHistoryQuery query,
  ) async {
    try {
      final response = await _remoteDataSource.getTransactionHistory(query);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> claimTaskReward(
    TaskRewardClaim claim,
  ) async {
    try {
      final response = await _remoteDataSource.claimTaskReward(claim);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> claimRewardedAd(
    RewardedAdClaim claim,
  ) async {
    try {
      final response = await _remoteDataSource.claimRewardedAd(claim);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> verifyPurchase(
    PurchaseVerificationRequest request,
  ) async {
    try {
      final response = await _remoteDataSource.verifyPurchase(request);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  @override
  Future<Either<Failure, LedgerMutationResult>> spendCoins(
    SpendCoinsCommand command,
  ) async {
    try {
      final response = await _remoteDataSource.spendCoins(command);
      return right(response.toDomain());
    } catch (error) {
      return left(_mapFailure(error));
    }
  }

  Failure _mapFailure(Object error) {
    if (error is DioException) {
      final int? statusCode = error.response?.statusCode;
      final String message = _extractMessage(error);

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.connectionError) {
        return NetworkFailure(message, meta: <String, dynamic>{'type': error.type.name});
      }

      if (statusCode == 402) {
        return InsufficientBalanceFailure(
          message,
          meta: <String, dynamic>{'statusCode': statusCode},
        );
      }

      if (statusCode == 409) {
        return DuplicateRewardFailure(
          message,
          meta: <String, dynamic>{'statusCode': statusCode},
        );
      }

      if (statusCode == 422) {
        return ValidationFailure(
          message,
          meta: <String, dynamic>{'statusCode': statusCode},
        );
      }

      if (statusCode == 423 || statusCode == 429) {
        return AntiFraudFailure(
          message,
          meta: <String, dynamic>{'statusCode': statusCode},
        );
      }

      return ServerFailure(
        message,
        meta: <String, dynamic>{'statusCode': statusCode},
      );
    }

    return UnexpectedFailure(
      'Unexpected coins repository failure.',
      meta: <String, dynamic>{'error': error.toString()},
    );
  }

  String _extractMessage(DioException error) {
    final dynamic data = error.response?.data;
    if (data is Map<String, dynamic>) {
      final Object? message = data['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }
    return error.message ?? 'A network request failed.';
  }
}
