import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:untitled2/features/ai_perspective_studio/domain/models/perspective_points.dart';

class AiCornerDetector {
  static Future<PerspectivePoints?> autoDetectCorners(ui.Image image) async {
    try {
      // 1. Convert ui.Image to a format ML Kit can use
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}${Platform.pathSeparator}ai_scan_input.png');
      await tempFile.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      // 2. Setup Object Detector
      final options = ObjectDetectorOptions(
        mode: DetectionMode.single,
        classifyObjects: true,
        multipleObjects: false,
      );
      final objectDetector = ObjectDetector(options: options);

      // 3. Process image
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final objects = await objectDetector.processImage(inputImage);

      // Cleanup
      await objectDetector.close();
      if (tempFile.existsSync()) await tempFile.delete();

      if (objects.isEmpty) return null;

      // 4. Map detected bounding box to PerspectivePoints
      // We take the first object as the primary target
      final obj = objects.first;
      final rect = obj.boundingBox;

      final double w = image.width.toDouble();
      final double h = image.height.toDouble();

      return PerspectivePoints(
        topLeft: Offset(rect.left.clamp(0, w), rect.top.clamp(0, h)),
        topRight: Offset(rect.right.clamp(0, w), rect.top.clamp(0, h)),
        bottomLeft: Offset(rect.left.clamp(0, w), rect.bottom.clamp(0, h)),
        bottomRight: Offset(rect.right.clamp(0, w), rect.bottom.clamp(0, h)),
      );
    } catch (e) {
      print('AI Detection Error: $e');
      return null;
    }
  }
}
