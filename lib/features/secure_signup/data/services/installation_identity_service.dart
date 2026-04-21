import 'package:untitled2/features/secure_signup/domain/entities/installation_context.dart';

abstract class InstallationIdentityService {
  Future<InstallationContext> getContext();
}
