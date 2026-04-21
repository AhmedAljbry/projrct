import 'package:equatable/equatable.dart';

class InstallationContext extends Equatable {
  const InstallationContext({
    required this.installationId,
    required this.platform,
    required this.appVersion,
    required this.buildNumber,
    required this.riskSignals,
  });

  final String installationId;
  final String platform;
  final String appVersion;
  final String buildNumber;
  final Map<String, Object?> riskSignals;

  @override
  List<Object?> get props => [
        installationId,
        platform,
        appVersion,
        buildNumber,
        riskSignals,
      ];
}
