import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../features/ads/data/admob_ads_repository.dart';
import '../features/auth/data/firebase_auth_repository.dart';
import '../features/coins/data/firestore_coins_repository.dart';
import '../features/device/data/device_fingerprint_data_source.dart';
import '../features/payments/data/play_billing_repository.dart';
import '../services/ads_service.dart';
import '../services/auth_service.dart';
import '../services/coins_service.dart';
import '../services/device_service.dart';
import '../services/purchase_service.dart';
import '../utils/module_logger.dart';
import '../utils/request_signer.dart';
import '../utils/safe_executor.dart';
import '../utils/sha256_hasher.dart';
import 'coins_system_config.dart';

class CoinsSystem {
  CoinsSystem._();

  static bool _initialized = false;
  static CoinsSystemConfig? _config;
  static AuthService _authService = AuthService.noop();
  static CoinsService _coinsService = CoinsService.noop();
  static AdsService _adsService = AdsService.noop();
  static DeviceService _deviceService = DeviceService.noop();
  static PurchaseService _purchaseService = PurchaseService.noop();

  static bool get isInitialized => _initialized;
  static CoinsSystemConfig? get config => _config;
  static AuthService get authService => _authService;
  static CoinsService get coinsService => _coinsService;
  static AdsService get adsService => _adsService;
  static DeviceService get deviceService => _deviceService;
  static PurchaseService get purchaseService => _purchaseService;

  static Future<bool> initialize({
    required FirebaseApp firebaseApp,
    required CoinsSystemConfig config,
  }) async {
    if (_initialized) {
      return true;
    }

    final logger = ModuleLogger(config.enableLogging);

    try {
      if (config.enableAppCheck) {
        await FirebaseAppCheck.instance.activate(
          androidProvider: config.androidAppCheckProvider,
          appleProvider: config.appleAppCheckProvider,
        );
      }

      await MobileAds.instance.initialize();

      final storage = const FlutterSecureStorage();
      final hasher = const Sha256Hasher();
      final requestSigner = RequestSigner(storage: storage, hasher: hasher);
      final deviceDataSource = DeviceFingerprintDataSource(
        requestSigner: requestSigner,
        hasher: hasher,
      );

      final firestore = FirebaseFirestore.instanceFor(app: firebaseApp);
      final functions = FirebaseFunctions.instanceFor(
        app: firebaseApp,
        region: config.functionsRegion,
      );
      final auth = FirebaseAuth.instanceFor(app: firebaseApp);

      final authRepository = FirebaseAuthRepository(
        firebaseAuth: auth,
        functions: functions,
        deviceDataSource: deviceDataSource,
        requestSigner: requestSigner,
        logger: logger,
        serverClientId: config.googleServerClientId,
      );
      final coinsRepository = FirestoreCoinsRepository(
        firestore: firestore,
        functions: functions,
        deviceDataSource: deviceDataSource,
        requestSigner: requestSigner,
      );
      final adsRepository = AdMobAdsRepository(
        rewardedAdUnitId: config.adMobRewardedUnitId,
      );
      final paymentsRepository = PlayBillingRepository(
        inAppPurchase: InAppPurchase.instance,
        functions: functions,
        auth: auth,
        deviceDataSource: deviceDataSource,
        requestSigner: requestSigner,
        productCoins: config.productCoins,
        packageName: config.androidPackageName,
      );

      _authService = AuthService(
        repository: authRepository,
        safeExecutor: const SafeExecutor(),
        logger: logger,
        enabled: true,
      );
      _coinsService = CoinsService(
        repository: coinsRepository,
        safeExecutor: const SafeExecutor(),
        logger: logger,
        enabled: true,
      );
      _adsService = AdsService(
        repository: adsRepository,
        coinsService: _coinsService,
        safeExecutor: const SafeExecutor(),
        logger: logger,
        enabled: true,
      );
      _deviceService = DeviceService(
        dataSource: deviceDataSource,
        safeExecutor: const SafeExecutor(),
        logger: logger,
        enabled: true,
      );
      _purchaseService = PurchaseService(
        repository: paymentsRepository,
        safeExecutor: const SafeExecutor(),
        logger: logger,
        enabled: true,
      );

      _config = config;
      _initialized = true;
      logger.info('Coins module initialized');
      return true;
    } catch (error, stackTrace) {
      logger.error('Coins module initialization failed', error, stackTrace);
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'coins_module',
          context: ErrorDescription('while initializing coins module'),
        ),
      );
      _authService = AuthService.noop();
      _coinsService = CoinsService.noop();
      _adsService = AdsService.noop();
      _deviceService = DeviceService.noop();
      _purchaseService = PurchaseService.noop();
      _config = config;
      _initialized = false;
      return false;
    }
  }
}
