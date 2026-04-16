import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../domain/ads_repository.dart';

class AdMobAdsRepository implements AdsRepository {
  AdMobAdsRepository({required String rewardedAdUnitId})
      : _rewardedAdUnitId = rewardedAdUnitId;

  final String _rewardedAdUnitId;
  RewardedAd? _rewardedAd;

  @override
  Future<bool> preloadRewardedAd() async {
    if (_rewardedAd != null) {
      return true;
    }
    final completer = Completer<bool>();
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          completer.complete(true);
        },
        onAdFailedToLoad: (_) => completer.complete(false),
      ),
    );
    return completer.future;
  }

  @override
  Future<bool> showRewardedAd(
      {required Future<void> Function() onRewarded}) async {
    final ad = _rewardedAd;
    if (ad == null) {
      final loaded = await preloadRewardedAd();
      if (!loaded || _rewardedAd == null) {
        return false;
      }
    }

    final completer = Completer<bool>();
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        unawaited(preloadRewardedAd());
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _rewardedAd = null;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
    );
    _rewardedAd!.show(
      onUserEarnedReward: (_, __) async {
        await onRewarded();
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      },
    );
    return completer.future;
  }
}
