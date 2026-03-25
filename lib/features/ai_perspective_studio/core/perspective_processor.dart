import 'dart:isolate';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../domain/models/perspective_points.dart';

class PerspectiveRequest {
  final Uint8List imageBytes;
  final PerspectivePoints points;
  final SendPort sendPort;

  PerspectiveRequest({
    required this.imageBytes,
    required this.points,
    required this.sendPort,
  });
}

class PerspectiveResponse {
  final Uint8List? resultBytes;
  final String? error;

  PerspectiveResponse({this.resultBytes, this.error});
}

class PerspectiveProcessor {
  static Future<Uint8List?> rectifyImage({
    required Uint8List imageBytes,
    required PerspectivePoints points,
  }) async {
    final receivePort = ReceivePort();
    
    await Isolate.spawn(
      _isolateWorker,
      PerspectiveRequest(
        imageBytes: imageBytes,
        points: points,
        sendPort: receivePort.sendPort,
      ),
    );

    final response = await receivePort.first as PerspectiveResponse;
    if (response.error != null) {
      debugPrint('PerspectiveProcessor Error: ${response.error}');
      return null;
    }
    return response.resultBytes;
  }

  static void _isolateWorker(PerspectiveRequest request) {
    try {
      final img.Image? src = img.decodeImage(request.imageBytes);
      if (src == null) {
        request.sendPort.send(PerspectiveResponse(error: 'Failed to decode image.'));
        return;
      }

      // Calculate output dimensions based on the quadrilateral edges
      final p1 = request.points.topLeft;
      final p2 = request.points.topRight;
      final p3 = request.points.bottomRight;
      final p4 = request.points.bottomLeft;

      final topWidth = sqrt(pow(p2.dx - p1.dx, 2) + pow(p2.dy - p1.dy, 2));
      final bottomWidth = sqrt(pow(p3.dx - p4.dx, 2) + pow(p3.dy - p4.dy, 2));
      final leftHeight = sqrt(pow(p4.dx - p1.dx, 2) + pow(p4.dy - p1.dy, 2));
      final rightHeight = sqrt(pow(p3.dx - p2.dx, 2) + pow(p3.dy - p2.dy, 2));

      final maxWidth = max(topWidth, bottomWidth).toInt();
      final maxHeight = max(leftHeight, rightHeight).toInt();

      final rectified = img.copyRectify(
        src,
        topLeft: img.Point(p1.dx.toInt(), p1.dy.toInt()),
        topRight: img.Point(p2.dx.toInt(), p2.dy.toInt()),
        bottomLeft: img.Point(p4.dx.toInt(), p4.dy.toInt()),
        bottomRight: img.Point(p3.dx.toInt(), p3.dy.toInt()),
        interpolation: img.Interpolation.linear,
      );
      
      // In the image package, copyRectify might return an image with same size as src if dimensions aren't specified.
      // Let's ensure we crop or resize if needed, but copyRectify usually does the job.
      // Actually, image 4.x copyRectify returns the rectified area mapped to the src size or a target size.
      // If we want it to be a clean crop of just the rectified area:
      final target = img.copyResize(rectified, width: maxWidth, height: maxHeight);

      final resultBytes = Uint8List.fromList(img.encodePng(target));
      request.sendPort.send(PerspectiveResponse(resultBytes: resultBytes));
    } catch (e) {
      request.sendPort.send(PerspectiveResponse(error: e.toString()));
    }
  }
}
