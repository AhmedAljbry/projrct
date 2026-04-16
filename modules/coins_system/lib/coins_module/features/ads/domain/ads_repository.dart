abstract class AdsRepository {
  Future<bool> preloadRewardedAd();
  Future<bool> showRewardedAd({required Future<void> Function() onRewarded});
}
