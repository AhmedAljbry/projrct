import 'package:get_it/get_it.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/logging/app_logger.dart';
import 'package:untitled2/features/ai_editor/data/datasources/ai_processing_remote_data_source.dart';
import 'package:untitled2/features/ai_editor/data/network/lama_dio_client.dart';
import 'package:untitled2/features/ai_editor/data/repositories/ai_processing_repository_impl.dart';
import 'package:untitled2/features/ai_editor/data/services/ai_image_preprocessor.dart';
import 'package:untitled2/features/ai_editor/data/services/ai_job_local_store.dart';
import 'package:untitled2/features/ai_editor/data/services/ai_secure_config_service.dart';
import 'package:untitled2/features/ai_editor/domain/repositories/ai_processing_repository.dart';
import 'package:untitled2/features/ai_editor/domain/usecases/get_job_result_use_case.dart';
import 'package:untitled2/features/ai_editor/domain/usecases/get_job_status_use_case.dart';
import 'package:untitled2/features/ai_editor/domain/usecases/submit_ai_job_use_case.dart';

final GetIt serviceLocator = GetIt.instance;

Future<void> setupServiceLocator(AppConfig config) async {
  if (!serviceLocator.isRegistered<AppConfig>()) {
    serviceLocator.registerSingleton<AppConfig>(config);
  }

  if (!serviceLocator.isRegistered<AppLogger>()) {
    serviceLocator.registerLazySingleton<AppLogger>(() => const AppLogger());
  }

  if (!serviceLocator.isRegistered<AiSecureConfigService>()) {
    final secureConfigService = AiSecureConfigService(
      storageFallbackApiKey: config.apiKey,
      storageFallbackOwnerId: config.ownerId,
      logger: serviceLocator<AppLogger>(),
    );
    await secureConfigService.bootstrap();
    serviceLocator.registerSingleton<AiSecureConfigService>(secureConfigService);
  }

  serviceLocator
    ..registerLazySingleton<LamaDioClient>(
      () => LamaDioClient(
        baseUrl: config.baseUrl,
        secureConfigService: serviceLocator<AiSecureConfigService>(),
        logger: serviceLocator<AppLogger>(),
      ),
    )
    ..registerLazySingleton<AiImagePreprocessor>(
      () => AiImagePreprocessor(logger: serviceLocator<AppLogger>()),
    )
    ..registerLazySingleton<AiJobLocalStore>(
      () => AiJobLocalStore(logger: serviceLocator<AppLogger>()),
    )
    ..registerLazySingleton<AiProcessingRemoteDataSource>(
      () => AiProcessingRemoteDataSourceImpl(
        client: serviceLocator<LamaDioClient>(),
        logger: serviceLocator<AppLogger>(),
      ),
    )
    ..registerLazySingleton<AiProcessingRepository>(
      () => AiProcessingRepositoryImpl(
        remoteDataSource: serviceLocator<AiProcessingRemoteDataSource>(),
        localStore: serviceLocator<AiJobLocalStore>(),
        imagePreprocessor: serviceLocator<AiImagePreprocessor>(),
        logger: serviceLocator<AppLogger>(),
      ),
    )
    ..registerLazySingleton<SubmitAiJobUseCase>(
      () => SubmitAiJobUseCase(serviceLocator<AiProcessingRepository>()),
    )
    ..registerLazySingleton<GetJobStatusUseCase>(
      () => GetJobStatusUseCase(serviceLocator<AiProcessingRepository>()),
    )
    ..registerLazySingleton<GetJobResultUseCase>(
      () => GetJobResultUseCase(serviceLocator<AiProcessingRepository>()),
    );
}
