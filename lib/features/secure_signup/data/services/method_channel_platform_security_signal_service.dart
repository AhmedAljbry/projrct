import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:untitled2/features/secure_signup/data/services/platform_security_signal_service.dart';

class MethodChannelPlatformSecuritySignalService
    implements PlatformSecuritySignalService {
  MethodChannelPlatformSecuritySignalService({
    MethodChannel? channel,
    DeviceInfoPlugin? deviceInfoPlugin,
  })  : _channel = channel ?? const MethodChannel(_channelName),
        _deviceInfoPlugin = deviceInfoPlugin ?? DeviceInfoPlugin();

  static const _channelName = 'app.security/signals';

  final MethodChannel _channel;
  final DeviceInfoPlugin _deviceInfoPlugin;

  @override
  Future<Map<String, Object?>> collectSignals() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return {
        'is_debug_build': kDebugMode,
      };
    }

    final nativeSignals =
        await _channel.invokeMapMethod<String, Object?>('getSecuritySignals') ??
            <String, Object?>{};
    final normalized = Map<String, Object?>.from(nativeSignals);
    normalized['is_debug_build'] = kDebugMode;

    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      normalized['is_physical_device'] = info.isPhysicalDevice;
      normalized['sdk_int'] = info.version.sdkInt;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      normalized['is_physical_device'] = info.isPhysicalDevice;
      normalized['system_version'] = info.systemVersion;
    }

    return normalized;
  }
}
