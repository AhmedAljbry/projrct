import 'package:firebase_app_check/firebase_app_check.dart';

class CoinsSystemConfig {
  const CoinsSystemConfig({
    required this.functionsRegion,
    required this.adMobRewardedUnitId,
    required this.googleServerClientId,
    required this.androidPackageName,
    this.enableLogging = false,
    this.enableAppCheck = true,
    this.androidAppCheckProvider = AndroidProvider.playIntegrity,
    this.appleAppCheckProvider = AppleProvider.appAttest,
    this.productCoins = const <String, int>{},
  });

  final String functionsRegion;
  final String adMobRewardedUnitId;
  final String googleServerClientId;
  final String androidPackageName;
  final bool enableLogging;
  final bool enableAppCheck;
  final AndroidProvider androidAppCheckProvider;
  final AppleProvider appleAppCheckProvider;
  final Map<String, int> productCoins;
}
