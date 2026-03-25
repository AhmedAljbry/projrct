import 'package:package_info_plus/package_info_plus.dart';

class UpdateService {
  // In a real app, this would be fetched from Firebase Remote Config or an API
  static const String _requiredMinVersion = "1.0.0"; // Mock minimum version
  
  static Future<bool> isUpdateRequired() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;

    return _isVersionLower(currentVersion, _requiredMinVersion);
  }

  static bool _isVersionLower(String current, String requiredVersion) {
    if (current == requiredVersion) return false;
    
    List<int> currentParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    List<int> requiredParts = requiredVersion.split('.').map((e) => int.tryParse(e) ?? 0).toList();

    for (int i = 0; i < requiredParts.length; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int r = requiredParts[i];
      if (c < r) return true;
      if (c > r) return false;
    }
    return false;
  }
}
