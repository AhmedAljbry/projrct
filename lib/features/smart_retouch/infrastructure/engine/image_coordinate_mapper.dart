import 'package:flutter/material.dart';

class ImageCoordinateMapper {
  /// Maps a point from screen/widget coordinates to the intrinsic pixels of the image
  /// Handles offset from interactive viewer and scale differences
  static Offset screenToImage(Offset screenPoint, Rect imageDisplayRect, Size originalImageSize) {
    if (imageDisplayRect.isEmpty) return screenPoint;
    
    // Calculate relative position within the display rect (0.0 to 1.0)
    final double relativeX = (screenPoint.dx - imageDisplayRect.left) / imageDisplayRect.width;
    final double relativeY = (screenPoint.dy - imageDisplayRect.top) / imageDisplayRect.height;
    
    // Map to intrinsic image pixels
    final double imageX = relativeX * originalImageSize.width;
    final double imageY = relativeY * originalImageSize.height;
    
    return Offset(imageX, imageY);
  }

  /// Maps a point from the intrinsic image pixels back to screen coordinates
  static Offset imageToScreen(Offset imagePoint, Rect imageDisplayRect, Size originalImageSize) {
    if (originalImageSize.isEmpty) return imagePoint;

    final double relativeX = imagePoint.dx / originalImageSize.width;
    final double relativeY = imagePoint.dy / originalImageSize.height;

    final double screenX = imageDisplayRect.left + (relativeX * imageDisplayRect.width);
    final double screenY = imageDisplayRect.top + (relativeY * imageDisplayRect.height);

    return Offset(screenX, screenY);
  }

  /// Calculates the display rect of the image within a given canvas size, assuming BoxFit.contain
  static Rect calculateImageDisplayRect({
    required Size canvasSize,
    required Size imageSize,
  }) {
    if (canvasSize.isEmpty || imageSize.isEmpty) return Rect.zero;

    final double widthRatio = canvasSize.width / imageSize.width;
    final double heightRatio = canvasSize.height / imageSize.height;

    final double scale = widthRatio < heightRatio ? widthRatio : heightRatio;

    final double displayWidth = imageSize.width * scale;
    final double displayHeight = imageSize.height * scale;

    final double left = (canvasSize.width - displayWidth) / 2;
    final double top = (canvasSize.height - displayHeight) / 2;

    return Rect.fromLTWH(left, top, displayWidth, displayHeight);
  }
}
