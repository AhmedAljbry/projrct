import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

/// Gallery write with platform-aware permission prompts.
Future<String?> saveJpegToGallery(Uint8List jpegBytes, {required String name}) async {
  if (jpegBytes.isEmpty) return 'Empty image';

  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    final photos = await Permission.photos.request();
    if (!photos.isGranted) {
      final storage = await Permission.storage.request();
      if (!storage.isGranted) {
        return 'Gallery permission denied';
      }
    }
  }

  try {
    await Gal.putImageBytes(jpegBytes, name: name);
    return null;
  } catch (e) {
    return e.toString();
  }
}
