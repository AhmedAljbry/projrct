class RequestDeviceOverrideApiRequest {
  const RequestDeviceOverrideApiRequest({
    required this.reason,
    required this.installationId,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.requestNonce,
    required this.requestTimestampMs,
    required this.riskSignals,
  });

  final String reason;
  final String installationId;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final String requestNonce;
  final int requestTimestampMs;
  final Map<String, Object?> riskSignals;

  Map<String, Object?> toJson() => {
        'reason': reason,
        'installation_id': installationId,
        'platform': platform,
        'app_version': appVersion,
        'build_number': buildNumber,
        'request_nonce': requestNonce,
        'request_timestamp_ms': requestTimestampMs,
        'risk_signals': riskSignals,
      };
}
