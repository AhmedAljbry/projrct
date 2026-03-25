import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/blemish_removal_engine.dart';
import 'package:untitled2/vv/engine_isolate_worker.dart';


/// Export quality options.
enum ExportQuality {
  /// Fast, good quality — suitable for in-app sharing.
  high,

  /// Slightly faster — suitable for social thumbnails.
  medium,
}

/// Result of an export operation.
class ExportResult {
  final Uint8List? pngBytes;
  final String? errorMessage;
  final Duration duration;

  const ExportResult.success(this.pngBytes, this.duration) : errorMessage = null;
  const ExportResult.failure(this.errorMessage, this.duration) : pngBytes = null;

  bool get isSuccess => pngBytes != null;
}

/// Renders all blemish operations onto the original image and encodes the result.
///
/// Processing flow:
///  1. Decode the source image into a raw RGBA pixel buffer.
///  2. Dispatch all operations to [EngineIsolateWorker.applyAll].
///  3. Encode the modified buffer back to PNG/JPEG.
///  4. Return final bytes to caller.
class ExportService {
  final EngineIsolateWorker _worker;

  ExportService(this._worker);

  /// Apply all [operations] to [sourceImage] and return the encoded result.
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
        // Nothing to apply — return original encoded.
        final byteData = await sourceImage.toByteData(format: format);
        sw.stop();
        return ExportResult.success(
          byteData!.buffer.asUint8List(), sw.elapsed,
        );
      }

      // 1. Decode source image to RGBA.
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

      // 2. Apply all operations via isolate worker.
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

      // 3. Re-encode the modified pixels to ui.Image.
      final codec = await _pixelsToImage(processedPixels, imgW, imgH);
      final frame = await codec.getNextFrame();
      final outputImage = frame.image;

      // 4. Encode to final format.
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

  Future<ui.Codec> _pixelsToImage(Uint8List pixels, int width, int height) async {
    final completer = Completer<ui.Codec>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      (image) {
        // We need the codec to animate; wrap via PNG encoding.
        image.toByteData(format: ui.ImageByteFormat.png).then((bytes) {
          ui.instantiateImageCodec(bytes!.buffer.asUint8List()).then(completer.complete);
        });
      },
    );
    return completer.future;
  }
}

// ignore: prefer_constructors_over_static_methods
