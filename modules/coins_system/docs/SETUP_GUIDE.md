# Coins Module Setup Guide

## What this adds

This module is isolated inside `modules/coins_system` and does nothing until `CoinsSystem.initialize()` is called from the host app.

## 1. Firebase services

Enable these products in the Firebase project:

- Authentication with Google provider
- Cloud Firestore
- Cloud Functions
- App Check

Deploy Firestore rules from [firestore.rules](/C:/Users/MK/StudioProjects/untitled2/modules/coins_system/firebase_backend/firestore.rules).

## 2. Flutter package usage

The host app already references the package by path. No existing app files were changed.

Import:

```dart
import 'package:coins_system/coins_module.dart';
```

Initialize only where you want the module to be active:

```dart
final ok = await CoinsSystem.initialize(
  firebaseApp: Firebase.app(),
  config: const CoinsSystemConfig(
    functionsRegion: 'us-central1',
    adMobRewardedUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/rewarded-unit',
    googleServerClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
    androidPackageName: 'com.example.app',
    enableLogging: true,
    productCoins: {
      'coins_50': 50,
      'coins_120': 120,
      'coins_500': 500,
    },
  ),
);
```

If initialization fails, all services remain in safe no-op mode.

## 3. Android configuration

Add Google Sign-In, App Check, AdMob, and Play Billing setup in the host app configuration files:

- `google-services.json`
- AdMob app id in Android manifest
- Play Integrity for App Check
- Google Play Billing products matching `productCoins`

Recommended production build:

```bash
flutter build apk --obfuscate --split-debug-info=build/app/outputs/symbols
```

## 4. Cloud Functions

Inside [functions package](/C:/Users/MK/StudioProjects/untitled2/modules/coins_system/firebase_backend/functions):

```bash
npm install
firebase deploy --only functions
```

Set runtime environment values before deploy:

```bash
firebase functions:secrets:set ANDROID_PACKAGE_NAME
firebase functions:secrets:set PLAY_PRODUCT_COINS
firebase functions:secrets:set AD_REWARD_COINS
firebase functions:secrets:set MAX_HOURLY_AD_REWARDS
```

If you prefer dotenv locally, use [.env.example](/C:/Users/MK/StudioProjects/untitled2/modules/coins_system/firebase_backend/functions/.env.example) as the template.

## 5. Google Play purchase verification

Grant the Firebase Functions service account access to Google Play Console with Android Publisher permissions. The `verifyPurchase` function uses the Google Play Developer API to validate purchase tokens and acknowledge purchases.
