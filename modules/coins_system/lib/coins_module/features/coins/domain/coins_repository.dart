import '../../../models/coin_transaction.dart';
import '../../../models/coins_user.dart';
import '../../../models/reward_result.dart';

abstract class CoinsRepository {
  Stream<CoinsUser> watchWallet(String userId);
  Future<CoinsUser> getWallet(String userId);
  Future<List<CoinTransaction>> getTransactions(String userId,
      {int limit = 20});
  Future<RewardResult> claimAdReward(String userId);
}
