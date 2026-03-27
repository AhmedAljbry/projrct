import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/engine_isolate_worker.dart';

enum ExportQuality {
  high,
  medium,
}

class ExportResult {
  final Uint8List? pngBytes;
  final String? errorMessage;
  final Duration duration;

  const ExportResult.success(this.pngBytes, this.duration) : errorMessage = null;
  const ExportResult.failure(this.errorMessage, this.duration) : pngBytes = null;

  bool get isSuccess => pngBytes != null;
}

class ExportService {
  final EngineIsolateWorker _worker;

  ExportService(this._worker);

  Future<ExportResult> export({
    required ui.Image sourceImage,
    required List<BlemishOperation> operations,
    ExportQuality quality = ExportQuality.high,
    ui.ImageByteFormat format = ui.ImageByteFormat.png,
    void Function(double progress)? onProgress,
  }) async {
    final sw = Stopwatch()..start();

    try {
      if (operations.isEmpty) {
        final byteData = await sourceImage.toByteData(format: format);
        sw.stop();
        return ExportResult.success(byteData!.buffer.asUint8List(), sw.elapsed);
      }

      onProgress?.call(0.05);
      final byteData = await sourceImage.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (byteData == null) {
        sw.stop();
        return ExportResult.failure('Failed to decode source image.', sw.elapsed);
      }

      final rawPixels = byteData.buffer.asUint8List();
      final imgW = sourceImage.width;
      final imgH = sourceImage.height;

      onProgress?.call(0.10);
      final processedPixels = await _worker.applyAll(
        imagePixels: rawPixels,
        imageWidth: imgW,
        imageHeight: imgH,
        operations: operations,
        mode: EngineQualityMode.finalQuality,
        onProgress: (completed, total) {
          final pct = 0.10 + 0.80 * (completed / total);
          onProgress?.call(pct);
        },
      );

      onProgress?.call(0.90);

      final outputImage = await _pixelsToImage(processedPixels, imgW, imgH);
      final outputBytes = await outputImage.toByteData(format: format);
      outputImage.dispose();

      sw.stop();
      onProgress?.call(1.0);
      return ExportResult.success(outputBytes!.buffer.asUint8List(), sw.elapsed);
    } catch (e, stack) {
      debugPrint('[ExportService] Export failed: $e\n$stack');
      sw.stop();
      return ExportResult.failure('Export error: $e', sw.elapsed);
    }
  }

  Future<ui.Image> _pixelsToImage(Uint8List pixels, int width, int height) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(pixels);
    try {
      final descriptor = ui.ImageDescriptor.raw(
        buffer,
        width: width,
        height: height,
        pixelFormat: ui.PixelFormat.rgba8888,
      );
      try {
        final codec = await descriptor.instantiateCodec();
        final frame = await codec.getNextFrame();
        return frame.image;
      } finally {
        descriptor.dispose();
      }
    } finally {
      buffer.dispose();
    }
  }
}

