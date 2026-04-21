import 'dart:io';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:untitled2/features/secure_signup/data/services/installation_identity_service.dart';
import 'package:untitled2/features/secure_signup/data/services/platform_security_signal_service.dart';
import 'package:untitled2/features/secure_signup/domain/entities/installation_context.dart';

class FirebaseInstallationIdentityService
    implements InstallationIdentityService {
  FirebaseInstallationIdentityService({
    required PlatformSecuritySignalService securitySignalService,
    FirebaseInstallations? firebaseAppInstallations,
  })  : _securitySignalService = securitySignalService,
        _firebaseAppInstallations =
            firebaseAppInstallations ?? FirebaseInstallations.instance;

  final PlatformSecuritySignalService _securitySignalService;
  final FirebaseInstallations _firebaseAppInstallations;

  @override
  Future<InstallationContext> getContext() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installationId = await _firebaseAppInstallations.getId();
    final riskSignals = await _securitySignalService.collectSignals();

    return InstallationContext(
      installationId: installationId,
      platform: Platform.operatingSystem,
      appVersion: packageInfo.version,
      buildNumber: packageInfo.buildNumber,
      riskSignals: riskSignals,
    );
  }
}
