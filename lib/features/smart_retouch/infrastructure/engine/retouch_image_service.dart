import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:untitled2/features/smart_retouch/domain/models/retouch_mode.dart';
import 'package:untitled2/features/smart_retouch/domain/models/retouch_operation.dart';

import 'processors/clone_processor.dart';
import 'processors/eraser_processor.dart';
import 'processors/heal_processor.dart';

class RetouchEngineRequest {
  final Uint8List sourceImageBytes;
  final Uint8List baseTargetBytes;
  final List<RetouchOperation> operations;
  final SendPort sendPort;

  RetouchEngineRequest({
    required this.sourceImageBytes,
    required this.baseTargetBytes,
    required this.operations,
    required this.sendPort,
  });
}

class RetouchEngineResponse {
  final Uint8List? resultBytes;
  final String? error;

  RetouchEngineResponse({this.resultBytes, this.error});
}

class RetouchImageService {
  static Future<Uint8List?> renderSingleOperationPreview({
    required Uint8List sourceImageBytes,
    required Uint8List currentImageBytes,
    required RetouchOperation operation,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateWorker,
      RetouchEngineRequest(
        sourceImageBytes: sourceImageBytes,
        baseTargetBytes: currentImageBytes,
        operations: [operation],
        sendPort: receivePort.sendPort,
      ),
    );

    final response = await receivePort.first as RetouchEngineResponse;
    if (response.error != null) {
      debugPrint('RetouchImageService Preview Error: ${response.error}');
      return null;
    }
    return response.resultBytes;
  }

  static Future<Uint8List?> renderOperations({
    required Uint8List originalImageBytes,
    required List<RetouchOperation> operations,
  }) async {
    final receivePort = ReceivePort();

    await Isolate.spawn(
      _isolateWorker,
      RetouchEngineRequest(
        sourceImageBytes: originalImageBytes,
        baseTargetBytes: originalImageBytes,
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
        sourceImageBytes: request.sourceImageBytes,
        baseTargetBytes: request.baseTargetBytes,
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
