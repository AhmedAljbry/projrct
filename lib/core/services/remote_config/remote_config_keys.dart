enum RemoteConfigKey {
  maintenanceMode('maintenance_mode', false),
  minSupportedVersion('min_supported_version', '1.0.0'),
  authRequireEmailVerification('auth_require_email_verification', true),
  experimentalAuthHero('experimental_auth_hero', false),
  monetizationEngineEnabled('monetization_engine_enabled', true),
  monetizationConfigJson('monetization_config_json', '');

  const RemoteConfigKey(this.key, this.defaultValue);

  final String key;
  final Object defaultValue;
}
