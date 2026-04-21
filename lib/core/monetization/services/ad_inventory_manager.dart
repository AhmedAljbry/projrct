import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';
import 'package:untitled2/core/monetization/domain/monetization_models.dart';
import 'package:untitled2/core/monetization/services/monetization_analytics.dart';

@lazySingleton
class AdInventoryManager {
  AdInventoryManager(this._talker, this._analytics);

  final Talker _talker;
  final MonetizationAnalytics _analytics;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  RewardedInterstitialAd? _rewardedInterstitialAd;
  AppOpenAd? _appOpenAd;
  bool _initialized = false;
  bool _isShowingFullScreen = false;

  bool get isShowingFullScreen => _isShowingFullScreen;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await MobileAds.instance.initialize();
    if (kDebugMode) {
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: const <String>['EMULATOR']),
      );
    }
    _initialized = true;
  }

  AdInventorySnapshot get inventorySnapshot => AdInventorySnapshot(
        interstitialReady: _interstitialAd != null,
        rewardedReady: _rewardedAd != null,
        rewardedInterstitialReady: _rewardedInterstitialAd != null,
        nativeReady: nativeAdUnitId != null,
        appOpenReady: _appOpenAd != null,
      );

  Future<void> preloadEligibleAds(MonetizationRemoteConfig config) async {
    if (!_initialized) {
      await initialize();
    }
    // Ads are preloaded opportunistically so the business flow never blocks on availability.
    if (config.enableInterstitials &&
        _interstitialAd == null &&
        _interstitialUnitId != null) {
      unawaited(_loadInterstitial());
    }
    if (config.enableRewarded && _rewardedAd == null && _rewardedUnitId != null) {
      unawaited(_loadRewarded());
    }
    if (config.enableRewardedInterstitials &&
        _rewardedInterstitialAd == null &&
        _rewardedInterstitialUnitId != null) {
      unawaited(_loadRewardedInterstitial());
    }
    if (config.enableAppOpenAds && _appOpenAd == null && _appOpenUnitId != null) {
      unawaited(_loadAppOpen());
    }
  }

  Future<AdShowResult> show(
    MonetizationAdFormat format,
    MonetizationPlacement placement,
  ) {
    return switch (format) {
      MonetizationAdFormat.interstitial => _showInterstitial(placement),
      MonetizationAdFormat.rewarded => _showRewarded(),
      MonetizationAdFormat.rewardedInterstitial => _showRewardedInterstitial(),
      MonetizationAdFormat.appOpen => _showAppOpen(),
      MonetizationAdFormat.none || MonetizationAdFormat.native =>
        Future<AdShowResult>.value(
          const AdShowResult(
            format: MonetizationAdFormat.none,
            outcome: MonetizationOutcome.skipped,
          ),
        ),
    };
  }

  Future<void> dispose() async {
    await _interstitialAd?.dispose();
    await _rewardedAd?.dispose();
    await _rewardedInterstitialAd?.dispose();
    await _appOpenAd?.dispose();
  }

  String? get nativeAdUnitId => _resolveUnitId(
        androidProd: const String.fromEnvironment('ADMOB_ANDROID_NATIVE_UNIT_ID'),
        iosProd: const String.fromEnvironment('ADMOB_IOS_NATIVE_UNIT_ID'),
        androidTest: 'ca-app-pub-3940256099942544/2247696110',
        iosTest: 'ca-app-pub-3940256099942544/3986624511',
      );

  Future<void> _loadInterstitial() async {
    final adUnitId = _interstitialUnitId;
    if (adUnitId == null) {
      return;
    }
    await _analytics.logAdLifecycle(
      phase: 'requested',
      placement: MonetizationPlacement.processStart,
      format: MonetizationAdFormat.interstitial,
    );
    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _analytics.logAdLifecycle(
            phase: 'loaded',
            placement: MonetizationPlacement.processStart,
            format: MonetizationAdFormat.interstitial,
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _talker.warning('Interstitial failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> _loadRewarded() async {
    final adUnitId = _rewardedUnitId;
    if (adUnitId == null) {
      return;
    }
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) => _rewardedAd = ad,
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _talker.warning('Rewarded failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<void> _loadRewardedInterstitial() async {
    final adUnitId = _rewardedInterstitialUnitId;
    if (adUnitId == null) {
      return;
    }
    RewardedInterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) => _rewardedInterstitialAd = ad,
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          _talker.warning(
            'Rewarded interstitial failed to load: ${error.message}',
          );
        },
      ),
    );
  }

  Future<void> _loadAppOpen() async {
    final adUnitId = _appOpenUnitId;
    if (adUnitId == null) {
      return;
    }
    await AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) => _appOpenAd = ad,
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _talker.warning('App open failed to load: ${error.message}');
        },
      ),
    );
  }

  Future<AdShowResult> _showInterstitial(
    MonetizationPlacement placement,
  ) async {
    final ad = _interstitialAd;
    if (ad == null) {
      return const AdShowResult(
        format: MonetizationAdFormat.interstitial,
        outcome: MonetizationOutcome.unavailable,
      );
    }
    final completer = Completer<AdShowResult>();
    // Full-screen callbacks dispose immediately to avoid memory leaks and stale references.
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingFullScreen = true;
        _analytics.logAdLifecycle(
          phase: 'shown',
          placement: placement,
          format: MonetizationAdFormat.interstitial,
        );
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreen = false;
        ad.dispose();
        _interstitialAd = null;
        unawaited(_loadInterstitial());
        if (!completer.isCompleted) {
          completer.complete(
            const AdShowResult(
              format: MonetizationAdFormat.interstitial,
              outcome: MonetizationOutcome.dismissed,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreen = false;
        ad.dispose();
        _interstitialAd = null;
        unawaited(_loadInterstitial());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.interstitial,
              outcome: MonetizationOutcome.failed,
              errorMessage: error.message,
            ),
          );
        }
      },
      onAdClicked: (ad) => _analytics.logAdLifecycle(
        phase: 'clicked',
        placement: placement,
        format: MonetizationAdFormat.interstitial,
      ),
    );
    ad.show();
    return completer.future;
  }

  Future<AdShowResult> _showRewarded() async {
    final ad = _rewardedAd;
    if (ad == null) {
      return const AdShowResult(
        format: MonetizationAdFormat.rewarded,
        outcome: MonetizationOutcome.unavailable,
      );
    }
    final completer = Completer<AdShowResult>();
    var rewardEarned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingFullScreen = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreen = false;
        ad.dispose();
        _rewardedAd = null;
        unawaited(_loadRewarded());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.rewarded,
              outcome: rewardEarned
                  ? MonetizationOutcome.rewarded
                  : MonetizationOutcome.dismissed,
              rewardEarned: rewardEarned,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreen = false;
        ad.dispose();
        _rewardedAd = null;
        unawaited(_loadRewarded());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.rewarded,
              outcome: MonetizationOutcome.failed,
              errorMessage: error.message,
            ),
          );
        }
      },
    );
    await ad.show(
      onUserEarnedReward: (_, __) {
        rewardEarned = true;
      },
    );
    return completer.future;
  }

  Future<AdShowResult> _showRewardedInterstitial() async {
    final ad = _rewardedInterstitialAd;
    if (ad == null) {
      return const AdShowResult(
        format: MonetizationAdFormat.rewardedInterstitial,
        outcome: MonetizationOutcome.unavailable,
      );
    }
    final completer = Completer<AdShowResult>();
    var rewardEarned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingFullScreen = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreen = false;
        ad.dispose();
        _rewardedInterstitialAd = null;
        unawaited(_loadRewardedInterstitial());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.rewardedInterstitial,
              outcome: rewardEarned
                  ? MonetizationOutcome.rewarded
                  : MonetizationOutcome.dismissed,
              rewardEarned: rewardEarned,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreen = false;
        ad.dispose();
        _rewardedInterstitialAd = null;
        unawaited(_loadRewardedInterstitial());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.rewardedInterstitial,
              outcome: MonetizationOutcome.failed,
              errorMessage: error.message,
            ),
          );
        }
      },
    );
    await ad.show(
      onUserEarnedReward: (_, __) {
        rewardEarned = true;
      },
    );
    return completer.future;
  }

  Future<AdShowResult> _showAppOpen() async {
    final ad = _appOpenAd;
    if (ad == null) {
      return const AdShowResult(
        format: MonetizationAdFormat.appOpen,
        outcome: MonetizationOutcome.unavailable,
      );
    }
    final completer = Completer<AdShowResult>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) => _isShowingFullScreen = true,
      onAdDismissedFullScreenContent: (ad) {
        _isShowingFullScreen = false;
        ad.dispose();
        _appOpenAd = null;
        unawaited(_loadAppOpen());
        if (!completer.isCompleted) {
          completer.complete(
            const AdShowResult(
              format: MonetizationAdFormat.appOpen,
              outcome: MonetizationOutcome.dismissed,
            ),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingFullScreen = false;
        ad.dispose();
        _appOpenAd = null;
        unawaited(_loadAppOpen());
        if (!completer.isCompleted) {
          completer.complete(
            AdShowResult(
              format: MonetizationAdFormat.appOpen,
              outcome: MonetizationOutcome.failed,
              errorMessage: error.message,
            ),
          );
        }
      },
    );
    ad.show();
    return completer.future;
  }

  String? get _interstitialUnitId => _resolveUnitId(
        androidProd: const String.fromEnvironment(
          'ADMOB_ANDROID_INTERSTITIAL_UNIT_ID',
        ),
        iosProd: const String.fromEnvironment('ADMOB_IOS_INTERSTITIAL_UNIT_ID'),
        androidTest: 'ca-app-pub-3940256099942544/1033173712',
        iosTest: 'ca-app-pub-3940256099942544/4411468910',
      );

  String? get _rewardedUnitId => _resolveUnitId(
        androidProd: const String.fromEnvironment('ADMOB_ANDROID_REWARDED_UNIT_ID'),
        iosProd: const String.fromEnvironment('ADMOB_IOS_REWARDED_UNIT_ID'),
        androidTest: 'ca-app-pub-3940256099942544/5224354917',
        iosTest: 'ca-app-pub-3940256099942544/1712485313',
      );

  String? get _rewardedInterstitialUnitId => _resolveUnitId(
        androidProd: const String.fromEnvironment(
          'ADMOB_ANDROID_REWARDED_INTERSTITIAL_UNIT_ID',
        ),
        iosProd: const String.fromEnvironment(
          'ADMOB_IOS_REWARDED_INTERSTITIAL_UNIT_ID',
        ),
        androidTest: 'ca-app-pub-3940256099942544/5354046379',
        iosTest: null,
      );

  String? get _appOpenUnitId => _resolveUnitId(
        androidProd: const String.fromEnvironment('ADMOB_ANDROID_APP_OPEN_UNIT_ID'),
        iosProd: const String.fromEnvironment('ADMOB_IOS_APP_OPEN_UNIT_ID'),
        androidTest: 'ca-app-pub-3940256099942544/9257395921',
        iosTest: 'ca-app-pub-3940256099942544/5575463023',
      );

  String? _resolveUnitId({
    required String androidProd,
    required String iosProd,
    required String? androidTest,
    required String? iosTest,
  }) {
    if (Platform.isAndroid) {
      return kDebugMode ? androidTest : (androidProd.isEmpty ? null : androidProd);
    }
    if (Platform.isIOS) {
      return kDebugMode ? iosTest : (iosProd.isEmpty ? null : iosProd);
    }
    return null;
  }
}
