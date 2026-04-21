import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:talker/talker.dart';

@lazySingleton
class AppCheckService {
  AppCheckService(this._talker);

  final Talker _talker;

  Future<void> activate() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.deviceCheck,
      );
    } catch (error, stackTrace) {
      _talker.warning('App Check activation failed', error, stackTrace);
    }
  }
}
