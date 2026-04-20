import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger_observer.dart';
import 'package:untitled2/app/studio_app.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/firebase/firebase_bootstrap.dart';
import 'package:untitled2/core/firebase/firebase_runtime_options.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/app_check/app_check_service.dart';
import 'package:untitled2/core/services/crashlytics/crash_reporter.dart';
import 'package:untitled2/core/services/remote_config/remote_config_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      final config = AppConfig.fromEnvironment();
      final prefs = await SharedPreferences.getInstance();
      final localeController = LocaleController(
        prefs,
        deviceLocale: ui.PlatformDispatcher.instance.locale,
      );
      await configureDependencies(
        appConfig: config,
        sharedPreferences: prefs,
        localeController: localeController,
      );
      final talker = getIt<Talker>();
      Bloc.observer = TalkerBlocObserver(talker: talker);
      final firebaseEnabled = await getIt<FirebaseBootstrap>().initialize();
      if (firebaseEnabled) {
        await getIt<AppCheckService>().activate();
        await getIt<RemoteConfigService>().initialize();
        await _wireCrashReporting();
      }
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0C0C0E),
        systemNavigationBarIconBrightness: Brightness.light,
      ));
      runApp(
        firebaseEnabled
            ? StudioApp(config: config, localeController: localeController)
            : const _FirebaseSetupApp(),
      );
    },
    (error, stackTrace) async {
      if (getIt.isRegistered<CrashReporter>() &&
          FirebaseRuntimeOptions.isConfigured) {
        await getIt<CrashReporter>().recordError(
          error,
          stackTrace,
          fatal: true,
        );
      }
      if (getIt.isRegistered<Talker>()) {
        getIt<Talker>().handle(error, stackTrace);
      }
    },
  );
}

Future<void> _wireCrashReporting() async {
  final reporter = getIt<CrashReporter>();
  FlutterError.onError = (details) async {
    await reporter.recordError(
      details.exception,
      details.stack ?? StackTrace.current,
      fatal: false,
      reason: details.context?.toDescription(),
    );
  };
  ui.PlatformDispatcher.instance.onError = (error, stackTrace) {
    reporter.recordError(error, stackTrace, fatal: true);
    return true;
  };
}

class _FirebaseSetupApp extends StatelessWidget {
  const _FirebaseSetupApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0C0C0E),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFF17171C),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firebase is not configured yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'This app expects Firebase values to be passed using --dart-define. Until those values are added, authentication and connected features stay disabled.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Required Android values:',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'FIREBASE_ANDROID_API_KEY\nFIREBASE_ANDROID_APP_ID\nFIREBASE_ANDROID_MESSAGING_SENDER_ID\nFIREBASE_ANDROID_PROJECT_ID\nFIREBASE_ANDROID_STORAGE_BUCKET',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
