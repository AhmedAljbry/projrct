import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class RenderCaptureService {
  const RenderCaptureService();

  Future<Uint8List?> capturePng(
    GlobalKey repaintKey, {
    double pixelRatio = 3,
  }) async {
    final context = repaintKey.currentContext;
    if (context == null) {
      return null;
    }

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return null;
    }

    final image = await renderObject.toImage(pixelRatio: pixelRatio);
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }
}
