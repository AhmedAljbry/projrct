import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  DefaultFirebaseOptions._();

  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      default:
        throw UnsupportedError('Firebase is not configured for this platform.');
    }
  }

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _require('FIREBASE_ANDROID_API_KEY'),
        appId: _require('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _require('FIREBASE_IOS_API_KEY'),
        appId: _require('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _require('FIREBASE_IOS_BUNDLE_ID'),
      );

  static FirebaseOptions get macos => FirebaseOptions(
        apiKey: _require('FIREBASE_MACOS_API_KEY'),
        appId: _require('FIREBASE_MACOS_APP_ID'),
        messagingSenderId: _require('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _require('FIREBASE_PROJECT_ID'),
        storageBucket: _require('FIREBASE_STORAGE_BUCKET'),
        iosBundleId: _require('FIREBASE_MACOS_BUNDLE_ID'),
      );

  static bool get hasEnvironmentConfiguration {
    return const String.fromEnvironment('FIREBASE_PROJECT_ID').isNotEmpty &&
        const String.fromEnvironment('FIREBASE_STORAGE_BUCKET').isNotEmpty &&
        const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID')
            .isNotEmpty &&
        const String.fromEnvironment('FIREBASE_ANDROID_API_KEY').isNotEmpty &&
        const String.fromEnvironment('FIREBASE_ANDROID_APP_ID').isNotEmpty;
  }

  static String _require(String key) {
    final value = switch (key) {
      'FIREBASE_ANDROID_API_KEY' =>
        const String.fromEnvironment('FIREBASE_ANDROID_API_KEY'),
      'FIREBASE_ANDROID_APP_ID' =>
        const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      'FIREBASE_IOS_API_KEY' =>
        const String.fromEnvironment('FIREBASE_IOS_API_KEY'),
      'FIREBASE_IOS_APP_ID' =>
        const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      'FIREBASE_MACOS_API_KEY' =>
        const String.fromEnvironment('FIREBASE_MACOS_API_KEY'),
      'FIREBASE_MACOS_APP_ID' =>
        const String.fromEnvironment('FIREBASE_MACOS_APP_ID'),
      'FIREBASE_MESSAGING_SENDER_ID' =>
        const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
      'FIREBASE_PROJECT_ID' =>
        const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      'FIREBASE_STORAGE_BUCKET' =>
        const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
      'FIREBASE_IOS_BUNDLE_ID' =>
        const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
      'FIREBASE_MACOS_BUNDLE_ID' =>
        const String.fromEnvironment('FIREBASE_MACOS_BUNDLE_ID'),
      _ => '',
    };
    if (value.isEmpty) {
      throw StateError('Missing Firebase define: $key');
    }
    return value;
  }
}
