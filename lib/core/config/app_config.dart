const _defaultInpaintingBaseUrl =
    'https://unimpairable-foggy-alia.ngrok-free.dev';

class AppConfig {
  final String baseUrl;
  final String? apiKey;
  final String? ownerId;
  final String? openAIApiKey;
  final String openAIVisionModel;
  final String openAIVisionDetail;
  final String openAIBaseUrl;

  const AppConfig({
    required this.baseUrl,
    this.apiKey,
    this.ownerId,
    this.openAIApiKey,
    this.openAIVisionModel = 'gpt-4.1-mini',
    this.openAIVisionDetail = 'high',
    this.openAIBaseUrl = 'https://api.openai.com/v1',
  });

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'LAMA_BASE_URL',
      defaultValue: _defaultInpaintingBaseUrl,
    );
    const rawApiKey = String.fromEnvironment('LAMA_API_KEY');
    const rawOwnerId = String.fromEnvironment('LAMA_OWNER_ID');
    const rawOpenAIApiKey = String.fromEnvironment('OPENAI_API_KEY');
    const openAIVisionModel = String.fromEnvironment(
      'OPENAI_VISION_MODEL',
      defaultValue: 'gpt-4.1-mini',
    );
    const openAIVisionDetail = String.fromEnvironment(
      'OPENAI_VISION_DETAIL',
      defaultValue: 'high',
    );
    const openAIBaseUrl = String.fromEnvironment(
      'OPENAI_BASE_URL',
      defaultValue: 'https://api.openai.com/v1',
    );

    return AppConfig(
      baseUrl: baseUrl,
      apiKey: rawApiKey.isEmpty ? null : rawApiKey,
      ownerId: rawOwnerId.isEmpty ? null : rawOwnerId,
      openAIApiKey: rawOpenAIApiKey.isEmpty ? null : rawOpenAIApiKey,
      openAIVisionModel: openAIVisionModel,
      openAIVisionDetail: openAIVisionDetail,
      openAIBaseUrl: openAIBaseUrl,
    );
  }
}
