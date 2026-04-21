class AppAnalyticsEvent {
  const AppAnalyticsEvent._(this.name, [this.parameters = const {}]);

  final String name;
  final Map<String, Object?> parameters;

  factory AppAnalyticsEvent.appOpen() {
    return const AppAnalyticsEvent._('app_open');
  }

  factory AppAnalyticsEvent.screenView({
    required String screenName,
    String? screenClass,
  }) {
    return AppAnalyticsEvent._(
      'screen_view',
      {
        'screen_name': screenName,
        if (screenClass != null) 'screen_class': screenClass,
      },
    );
  }

  factory AppAnalyticsEvent.onboardingOpened() {
    return const AppAnalyticsEvent._('onboarding_opened');
  }

  factory AppAnalyticsEvent.editorOpened({required String editor}) {
    return AppAnalyticsEvent._('editor_opened', {'editor': editor});
  }

  factory AppAnalyticsEvent.featureUsed({required String feature}) {
    return AppAnalyticsEvent._('feature_used', {'feature': feature});
  }

  factory AppAnalyticsEvent.imageImported({required String source}) {
    return AppAnalyticsEvent._('image_imported', {'source': source});
  }

  factory AppAnalyticsEvent.processingStarted({required String flow}) {
    return AppAnalyticsEvent._('processing_started', {'flow': flow});
  }

  factory AppAnalyticsEvent.processingCompleted({required String flow}) {
    return AppAnalyticsEvent._('processing_completed', {'flow': flow});
  }

  factory AppAnalyticsEvent.processingFailed({
    required String flow,
    String? reason,
  }) {
    return AppAnalyticsEvent._(
      'processing_failed',
      {'flow': flow, if (reason != null) 'reason': reason},
    );
  }

  factory AppAnalyticsEvent.exportStarted({required String flow}) {
    return AppAnalyticsEvent._('export_started', {'flow': flow});
  }

  factory AppAnalyticsEvent.exportCompleted({required String flow}) {
    return AppAnalyticsEvent._('export_completed', {'flow': flow});
  }

  factory AppAnalyticsEvent.purchaseFlowOpened() {
    return const AppAnalyticsEvent._('purchase_flow_opened');
  }

  factory AppAnalyticsEvent.settingsOpened() {
    return const AppAnalyticsEvent._('settings_opened');
  }

  factory AppAnalyticsEvent.languageChanged({required String languageCode}) {
    return AppAnalyticsEvent._(
      'language_changed',
      {'language_code': languageCode},
    );
  }

  factory AppAnalyticsEvent.helpOpened({required String topic}) {
    return AppAnalyticsEvent._('help_opened', {'topic': topic});
  }

  factory AppAnalyticsEvent.offlineStateSeen({required String source}) {
    return AppAnalyticsEvent._('offline_state_seen', {'source': source});
  }

  factory AppAnalyticsEvent.errorTracked({
    required String area,
    required String type,
  }) {
    return AppAnalyticsEvent._(
      'error_event',
      {
        'area': area,
        'type': type,
      },
    );
  }
}
