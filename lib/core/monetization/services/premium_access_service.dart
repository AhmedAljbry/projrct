import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@lazySingleton
class PremiumAccessService {
  PremiumAccessService(this._sharedPreferences);

  static const String _premiumKey = 'monetization.is_premium';
  static const String _noAdsKey = 'monetization.has_no_ads';

  final SharedPreferences _sharedPreferences;

  bool get isPremiumUser => _sharedPreferences.getBool(_premiumKey) ?? false;

  bool get hasNoAdsEntitlement => _sharedPreferences.getBool(_noAdsKey) ?? false;

  Future<void> setPremiumUser(bool value) async {
    await _sharedPreferences.setBool(_premiumKey, value);
  }

  Future<void> setNoAdsEntitlement(bool value) async {
    await _sharedPreferences.setBool(_noAdsKey, value);
  }
}
