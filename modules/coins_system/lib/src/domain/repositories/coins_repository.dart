import '../../core/usecase/use_case.dart';
import '../entities/coins_models.dart';

abstract class CoinsRepository {
  ResultFuture<WalletOverview> getWalletOverview(String userId);

  ResultFuture<TransactionPage> getTransactionHistory(TransactionHistoryQuery query);

  ResultFuture<LedgerMutationResult> claimTaskReward(TaskRewardClaim claim);

  ResultFuture<LedgerMutationResult> claimRewardedAd(RewardedAdClaim claim);

  ResultFuture<LedgerMutationResult> verifyPurchase(
    PurchaseVerificationRequest request,
  );

  ResultFuture<LedgerMutationResult> spendCoins(SpendCoinsCommand command);
}
