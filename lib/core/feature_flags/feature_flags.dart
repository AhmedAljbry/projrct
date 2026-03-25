class FeatureFlags {
  final bool adsEnabled;
  const FeatureFlags({required this.adsEnabled});

  static const dev = FeatureFlags(adsEnabled: false);
  static const prod = FeatureFlags(adsEnabled: false); // تبقى false حتى تقول أنت
}
class AdsService {
  final bool enabled;
  AdsService(this.enabled);

  Future<void> init() async {
    if (!enabled) return; // LOCKED
    // later: initialize SDK
  }
}