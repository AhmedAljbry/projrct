import 'package:equatable/equatable.dart';

class RestrictedSignupApiRequest extends Equatable {
  const RestrictedSignupApiRequest({
    required this.installationId,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.displayName,
    required this.email,
    required this.requestNonce,
    required this.requestTimestampMs,
    required this.riskSignals,
  });

  final String installationId;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final String displayName;
  final String email;
  final String requestNonce;
  final int requestTimestampMs;
  final Map<String, Object?> riskSignals;

  Map<String, Object?> toJson() => {
        'installation_id': installationId,
        'platform': platform,
        'app_version': appVersion,
        'build_number': buildNumber,
        'display_name': displayName,
        'email': email,
        'request_nonce': requestNonce,
        'request_timestamp_ms': requestTimestampMs,
        'risk_signals': riskSignals,
      };

  @override
  List<Object?> get props => [
        installationId,
        platform,
        appVersion,
        buildNumber,
        displayName,
        email,
        requestNonce,
        requestTimestampMs,
        riskSignals,
      ];
}
