import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import '../core/security/anti_fraud_policy.dart';
import '../data/remote/coins_api_service.dart';
import 'coins_injection.config.dart';

final GetIt coinsLocator = GetIt.asNewInstance();

class CoinsConfig {
  const CoinsConfig({
    required this.baseUrl,
    this.authToken,
    this.defaultHeaders = const <String, String>{},
  });

  final String baseUrl;
  final String? authToken;
  final Map<String, String> defaultHeaders;
}

@InjectableInit(
  initializerName: 'initCoinsLocator',
  preferRelativeImports: true,
)
Future<GetIt> configureCoinsDependencies(CoinsConfig config) async {
  await coinsLocator.reset();
  coinsLocator.registerSingleton<CoinsConfig>(config);
  coinsLocator.registerLazySingleton<Dio>(
    () => Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        contentType: Headers.jsonContentType,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        sendTimeout: const Duration(seconds: 20),
        headers: <String, dynamic>{
          'Accept': 'application/json',
          ...config.defaultHeaders,
          if (config.authToken != null) 'Authorization': 'Bearer ${config.authToken}',
        },
      ),
    ),
  );
  coinsLocator.registerLazySingleton<CoinsApiService>(
    () => CoinsApiService(
      coinsLocator<Dio>(),
      baseUrl: config.baseUrl,
    ),
  );
  coinsLocator.registerLazySingleton<AntiFraudPolicy>(() => const AntiFraudPolicy());
  return coinsLocator.initCoinsLocator();
}
