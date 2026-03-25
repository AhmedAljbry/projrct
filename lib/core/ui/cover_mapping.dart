import 'dart:math' as math;

import 'package:flutter/material.dart';

Rect applyBoxFitRect({
  required Size inputImageSize,
  required Size outputSize,
  BoxFit fit = BoxFit.contain,
}) {
  final iw = inputImageSize.width;
  final ih = inputImageSize.height;
  final ow = outputSize.width;
  final oh = outputSize.height;

  switch (fit) {
    case BoxFit.cover:
    case BoxFit.contain:
      final scale = fit == BoxFit.cover
          ? math.max(ow / iw, oh / ih)
          : math.min(ow / iw, oh / ih);
      final scaledW = iw * scale;
      final scaledH = ih * scale;
      final dx = (ow - scaledW) / 2.0;
      final dy = (oh - scaledH) / 2.0;
      return Rect.fromLTWH(dx, dy, scaledW, scaledH);
    default:
      final fitted = applyBoxFit(fit, inputImageSize, outputSize);
      final dx = (outputSize.width - fitted.destination.width) / 2.0;
      final dy = (outputSize.height - fitted.destination.height) / 2.0;
      return Rect.fromLTWH(
        dx,
        dy,
        fitted.destination.width,
        fitted.destination.height,
      );
  }
}

Rect applyBoxFitContainRect({
  required Size inputImageSize,
  required Size outputSize,
}) {
  return applyBoxFitRect(
    inputImageSize: inputImageSize,
    outputSize: outputSize,
    fit: BoxFit.contain,
  );
}

Rect applyBoxFitCoverRect({
  required Size inputImageSize, // imageW,imageH
  required Size outputSize, // widgetW,widgetH
}) {
  return applyBoxFitRect(
    inputImageSize: inputImageSize,
    outputSize: outputSize,
    fit: BoxFit.cover,
  );
}

/// widget point -> image normalized (0..1), respecting the selected BoxFit
Offset? widgetPointToImage01({
  required Offset widgetPoint,
  required Size widgetSize,
  required int imageW,
  required int imageH,
  BoxFit fit = BoxFit.contain,
}) {
  final imageRect = applyBoxFitRect(
    inputImageSize: Size(imageW.toDouble(), imageH.toDouble()),
    outputSize: widgetSize,
    fit: fit,
  );

  final localX = widgetPoint.dx - imageRect.left;
  final localY = widgetPoint.dy - imageRect.top;

  if (localX < 0 ||
      localY < 0 ||
      localX > imageRect.width ||
      localY > imageRect.height) {
    return null;
  }

  final nx = (localX / imageRect.width).clamp(0.0, 1.0);
  final ny = (localY / imageRect.height).clamp(0.0, 1.0);
  return Offset(nx, ny);
}

/// image normalized (0..1) -> widget point, respecting the selected BoxFit
Offset image01ToWidgetPoint({
  required Offset p01,
  required Size widgetSize,
  required int imageW,
  required int imageH,
  BoxFit fit = BoxFit.contain,
}) {
  final imageRect = applyBoxFitRect(
    inputImageSize: Size(imageW.toDouble(), imageH.toDouble()),
    outputSize: widgetSize,
    fit: fit,
  );

  final x = imageRect.left + (p01.dx * imageRect.width);
  final y = imageRect.top + (p01.dy * imageRect.height);
  return Offset(x, y);
}
