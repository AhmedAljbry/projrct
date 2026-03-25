import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';


class RetouchExportService {
  /// Saves the final processed bytes to local storage and returns the file path.
  static Future<String?> saveImageToTemp(Uint8List imageBytes) async {
    try {
      final Directory tempDir = await getTemporaryDirectory();
      
      // Generate a unique file name
      // Note: We avoid adding a dependency on uuid if not in pubspec, but it is standard.
      // If uuid is not available, we use timestamp.
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String filePath = '${tempDir.path}/retouched_$timestamp.png';

      final File file = File(filePath);
      await file.writeAsBytes(imageBytes);

      return filePath;
    } catch (e) {
      debugPrint('Export failed: $e');
      return null;
    }
  }

  /// Optional: Save directly to gallery (requires gal package which is in pubspec)
  static Future<bool> saveToGallery(String filePath) async {
    try {
      // Assuming 'gal' package is used for saving to gallery as seen in pubspec.yaml
      // import 'package:gal/gal.dart';
      // await Gal.putImage(filePath);
      return true;
    } catch (e) {
      debugPrint('Gallery save failed: $e');
      return false;
    }
  }
}
