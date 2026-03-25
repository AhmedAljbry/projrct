

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/feature_flags/feature_flags.dart';
import 'package:untitled2/inpainting/data/inpainting_api.dart';
import 'package:untitled2/inpainting/data/inpainting_repository.dart';

class AppDependencies {
  final AppConfig config;
  final FeatureFlags flags;
  final String langCode;

  AppDependencies({
    required this.config,
    required this.flags,
    required this.langCode,
  });

  late final InpaintingApi inpaintingApi = InpaintingApi(baseUrl: config.baseUrl);
  late final InpaintingRepository inpaintingRepository = InpaintingRepository(
    inpaintingApi,
    apiKey: config.apiKey,
    lang: langCode,
  );
}
