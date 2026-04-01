import 'package:injectable/injectable.dart';

import '../../domain/entities/coins_models.dart';
import '../models/coins_dtos.dart';
import 'coins_api_service.dart';

abstract class CoinsRemoteDataSource {
  Future<WalletOverviewDto> getWalletOverview(String userId);

  Future<TransactionPageDto> getTransactionHistory(TransactionHistoryQuery query);

  Future<LedgerMutationResultDto> claimTaskReward(TaskRewardClaim claim);

  Future<LedgerMutationResultDto> claimRewardedAd(RewardedAdClaim claim);

  Future<LedgerMutationResultDto> verifyPurchase(
    PurchaseVerificationRequest request,
  );

  Future<LedgerMutationResultDto> spendCoins(SpendCoinsCommand command);
}

@LazySingleton(as: CoinsRemoteDataSource)
class CoinsRemoteDataSourceImpl implements CoinsRemoteDataSource {
  CoinsRemoteDataSourceImpl(this._apiService);

  final CoinsApiService _apiService;

  @override
  Future<WalletOverviewDto> getWalletOverview(String userId) {
    return _apiService.getWalletOverview(userId);
  }

  @override
  Future<TransactionPageDto> getTransactionHistory(TransactionHistoryQuery query) {
    return _apiService.getTransactionHistory(query.userId, query.cursor, query.limit);
  }

  @override
  Future<LedgerMutationResultDto> claimTaskReward(TaskRewardClaim claim) {
    return _apiService.claimTaskReward(
      TaskRewardClaimRequestDto.fromDomain(claim).toJson(),
      claim.idempotencyKey,
    );
  }

  @override
  Future<LedgerMutationResultDto> claimRewardedAd(RewardedAdClaim claim) {
    return _apiService.claimRewardedAd(
      RewardedAdClaimRequestDto.fromDomain(claim).toJson(),
      claim.idempotencyKey,
    );
  }

  @override
  Future<LedgerMutationResultDto> verifyPurchase(
    PurchaseVerificationRequest request,
  ) {
    return _apiService.verifyPurchase(
      PurchaseVerificationRequestDto.fromDomain(request).toJson(),
      request.idempotencyKey,
    );
  }

  @override
  Future<LedgerMutationResultDto> spendCoins(SpendCoinsCommand command) {
    return _apiService.spendCoins(
      SpendCoinsRequestDto.fromDomain(command).toJson(),
      command.resolvedIdempotencyKey,
    );
  }
}
