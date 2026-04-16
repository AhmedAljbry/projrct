import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../utils/request_signer.dart';
import '../../../utils/sha256_hasher.dart';
import '../domain/device_fingerprint.dart';

class DeviceFingerprintDataSource {
  DeviceFingerprintDataSource({
    required RequestSigner requestSigner,
    required Sha256Hasher hasher,
    DeviceInfoPlugin? deviceInfo,
  })  : _requestSigner = requestSigner,
        _hasher = hasher,
        _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  final RequestSigner _requestSigner;
  final Sha256Hasher _hasher;
  final DeviceInfoPlugin _deviceInfo;

  Future<DeviceFingerprint> createFingerprint() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installTimestamp = await _requestSigner.getOrCreateInstallTimestamp();
    final installId = await _requestSigner.getOrCreateInstallId();
    final attributes = <String, String>{
      'platform': Platform.operatingSystem,
      'appId': packageInfo.packageName,
      'version': packageInfo.version,
      'buildNumber': packageInfo.buildNumber,
      'installTimestamp': '$installTimestamp',
      'installId': installId,
    };

    if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      attributes.addAll(<String, String>{
        'brand': info.brand,
        'model': info.model,
        'device': info.device,
        'manufacturer': info.manufacturer,
        'hardware': info.hardware,
        'product': info.product,
      });
    } else if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      attributes.addAll(<String, String>{
        'name': info.name,
        'model': info.model,
        'systemName': info.systemName,
        'systemVersion': info.systemVersion,
        'vendorId': info.identifierForVendor ?? '',
      });
    }

    final canonical = attributes.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final source =
        canonical.map((entry) => '${entry.key}=${entry.value}').join('|');
    final deviceHash = _hasher.hash(source);
    final fingerprintSignature = _hasher.hash('$source|fingerprint');
    return DeviceFingerprint(
      deviceHash: deviceHash,
      fingerprintSignature: fingerprintSignature,
      installTimestamp: installTimestamp,
      installId: installId,
      attributes: attributes,
    );
  }
}
