import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';
import 'package:untitled2/features/smart_retouch/domain/models/retouch_operation.dart';

import 'processors/clone_processor.dart';
import 'processors/heal_processor.dart';
import 'processors/eraser_processor.dart';

class RetouchEngineRequest {
  final Uint8List originalImageBytes;
  final List<RetouchOperation> operations;
  final SendPort sendPort;

  RetouchEngineRequest({
    required this.originalImageBytes,
    required this.operations,
    required this.sendPort,
  });
}

class RetouchEngineResponse {
  final Uint8List? resultBytes;
  final String? error;

  RetouchEngineResponse({this.resultBytes, this.error});
}

/// A service to run all pixel operations in a background isolate
/// This keeps the Flutter UI thread at 60fps while rendering high quality results
class RetouchImageService {
  static Future<Uint8List?> renderSingleOperationPreview({
    required Uint8List sourceImageBytes,
    required Uint8List currentImageBytes,
    required RetouchOperation operation,
  }) async {
    try {
      return _render(
        sourceImageBytes: sourceImageBytes,
        baseTargetBytes: currentImageBytes,
        operations: [operation],
      );
    } catch (e) {
      debugPrint('RetouchImageService Preview Error: $e');
      return null;
    }
  }

  static Future<Uint8List?> renderOperations({
    required Uint8List originalImageBytes,
    required List<RetouchOperation> operations,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateWorker,
      RetouchEngineRequest(
        originalImageBytes: originalImageBytes,
        operations: operations,
        sendPort: receivePort.sendPort,
      ),
    );

    final response = await receivePort.first as RetouchEngineResponse;
    if (response.error != null) {
      debugPrint('RetouchImageService Error: ${response.error}');
      return null;
    }
    return response.resultBytes;
  }

  static void _isolateWorker(RetouchEngineRequest request) {
    try {
      final Uint8List resultBytes = _render(
        sourceImageBytes: request.originalImageBytes,
        baseTargetBytes: request.originalImageBytes,
        operations: request.operations,
      );
      request.sendPort.send(RetouchEngineResponse(resultBytes: resultBytes));
    } catch (e) {
      request.sendPort.send(RetouchEngineResponse(error: e.toString()));
    }
  }

  static Uint8List _render({
    required Uint8List sourceImageBytes,
    required Uint8List baseTargetBytes,
    required List<RetouchOperation> operations,
  }) {
    final img.Image? rawOriginal = img.decodeImage(sourceImageBytes);
    if (rawOriginal == null) {
      throw StateError('Failed to decode source image.');
    }

    final img.Image? rawBaseTarget = img.decodeImage(baseTargetBytes);
    if (rawBaseTarget == null) {
      throw StateError('Failed to decode target image.');
    }

    final img.Image original = rawOriginal.convert(numChannels: 4);
    final img.Image target = rawBaseTarget.convert(numChannels: 4);

    for (final op in operations) {
      if (op is StrokeOperation) {
        switch (op.mode) {
          case RetouchMode.clone:
            CloneProcessor.processClone(
              targetImage: target,
              originalImage: original,
              operation: op,
            );
            break;
          case RetouchMode.heal:
            HealProcessor.processHeal(
              targetImage: target,
              originalImage: original,
              operation: op,
            );
            break;
          default:
            break;
        }
      } else if (op is EraseOperation) {
        EraserProcessor.processErase(
          targetImage: target,
          originalImage: original,
          operation: op,
        );
      }
    }

    return Uint8List.fromList(img.encodePng(target));
  }
}
