import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseRuntimeOptions {
  static const _androidApiKey =
      String.fromEnvironment('FIREBASE_ANDROID_API_KEY');
  static const _androidAppId =
      String.fromEnvironment('FIREBASE_ANDROID_APP_ID');
  static const _androidMessagingSenderId = String.fromEnvironment(
    'FIREBASE_ANDROID_MESSAGING_SENDER_ID',
  );
  static const _androidProjectId = String.fromEnvironment(
    'FIREBASE_ANDROID_PROJECT_ID',
  );
  static const _androidStorageBucket = String.fromEnvironment(
    'FIREBASE_ANDROID_STORAGE_BUCKET',
  );

  static const _iosApiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _iosMessagingSenderId = String.fromEnvironment(
    'FIREBASE_IOS_MESSAGING_SENDER_ID',
  );
  static const _iosProjectId =
      String.fromEnvironment('FIREBASE_IOS_PROJECT_ID');
  static const _iosStorageBucket = String.fromEnvironment(
    'FIREBASE_IOS_STORAGE_BUCKET',
  );
  static const _iosBundleId = String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID');

  static const _webApiKey = String.fromEnvironment('FIREBASE_WEB_API_KEY');
  static const _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const _webMessagingSenderId = String.fromEnvironment(
    'FIREBASE_WEB_MESSAGING_SENDER_ID',
  );
  static const _webProjectId =
      String.fromEnvironment('FIREBASE_WEB_PROJECT_ID');
  static const _webStorageBucket = String.fromEnvironment(
    'FIREBASE_WEB_STORAGE_BUCKET',
  );
  static const _webAuthDomain =
      String.fromEnvironment('FIREBASE_WEB_AUTH_DOMAIN');

  static bool get isConfigured {
    if (kIsWeb) {
      return _webApiKey.isNotEmpty &&
          _webAppId.isNotEmpty &&
          _webMessagingSenderId.isNotEmpty &&
          _webProjectId.isNotEmpty;
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _androidApiKey.isNotEmpty &&
          _androidAppId.isNotEmpty &&
          _androidMessagingSenderId.isNotEmpty &&
          _androidProjectId.isNotEmpty,
      TargetPlatform.iOS => _iosApiKey.isNotEmpty &&
          _iosAppId.isNotEmpty &&
          _iosMessagingSenderId.isNotEmpty &&
          _iosProjectId.isNotEmpty &&
          _iosBundleId.isNotEmpty,
      _ => false,
    };
  }

  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return FirebaseOptions(
        apiKey: _webApiKey,
        appId: _webAppId,
        messagingSenderId: _webMessagingSenderId,
        projectId: _webProjectId,
        storageBucket: _webStorageBucket.isEmpty ? null : _webStorageBucket,
        authDomain: _webAuthDomain.isEmpty ? null : _webAuthDomain,
      );
    }

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => FirebaseOptions(
          apiKey: _androidApiKey,
          appId: _androidAppId,
          messagingSenderId: _androidMessagingSenderId,
          projectId: _androidProjectId,
          storageBucket:
              _androidStorageBucket.isEmpty ? null : _androidStorageBucket,
        ),
      TargetPlatform.iOS => FirebaseOptions(
          apiKey: _iosApiKey,
          appId: _iosAppId,
          messagingSenderId: _iosMessagingSenderId,
          projectId: _iosProjectId,
          storageBucket: _iosStorageBucket.isEmpty ? null : _iosStorageBucket,
          iosBundleId: _iosBundleId,
        ),
      _ => throw UnsupportedError(
          'FirebaseRuntimeOptions only supports Android, iOS, and Web.',
        ),
    };
  }
}
