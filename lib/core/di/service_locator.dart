import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';

final GetIt serviceLocator = getIt;

Future<void> setupServiceLocator(
  AppConfig config, {
  required SharedPreferences sharedPreferences,
  required LocaleController localeController,
}) {
  return configureDependencies(
    appConfig: config,
    sharedPreferences: sharedPreferences,
    localeController: localeController,
  );
}
