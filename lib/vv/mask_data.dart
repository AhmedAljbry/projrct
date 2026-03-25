import 'dart:math' as math;
import 'dart:typed_data';
import 'package:meta/meta.dart';

/// Float-precision mask for a local editing region.
/// Pixels are stored in row-major order as Float32 values in [0.0, 1.0].
/// 0.0 = fully transparent (unaffected), 1.0 = fully opaque (fully healed).
@immutable
class MaskData {
  /// Width of the mask in pixels.
  final int width;

  /// Height of the mask in pixels.
  final int height;

  /// Flat Float32 buffer, length = width * height.
  final Float32List pixels;

  /// Axis-aligned bounding rectangle in the original image coordinate space.
  final MaskBounds bounds;

  const MaskData({
    required this.width,
    required this.height,
    required this.pixels,
    required this.bounds,
  });

  factory MaskData.empty(int width, int height, MaskBounds bounds) {
    return MaskData(
      width: width,
      height: height,
      pixels: Float32List(width * height),
      bounds: bounds,
    );
  }

  /// Creates a single soft circular dab mask centred at [cx, cy] relative to
  /// the mask's own coordinate space.
  factory MaskData.circularDab({
    required double cx,
    required double cy,
    required double radius,
    required double softness,
    required MaskBounds bounds,
  }) {
    final w = (radius * 2).ceil() + 2;
    final h = (radius * 2).ceil() + 2;
    final pixels = Float32List(w * h);
    final hardRadius = radius * (1.0 - softness.clamp(0.0, 0.99));

    for (int py = 0; py < h; py++) {
      for (int px = 0; px < w; px++) {
        final dx = px - cx;
        final dy = py - cy;
        final dist = math.sqrt(dx * dx + dy * dy);
        double alpha;
        if (dist <= hardRadius) {
          alpha = 1.0;
        } else if (dist < radius) {
          // Smooth cosine falloff in the soft zone.
          final t = (dist - hardRadius) / (radius - hardRadius);
          alpha = 0.5 + 0.5 * math.cos(math.pi * t);
        } else {
          alpha = 0.0;
        }
        pixels[py * w + px] = alpha.clamp(0.0, 1.0);
      }
    }

    return MaskData(width: w, height: h, pixels: pixels, bounds: bounds);
  }

  /// Merge two masks by taking the maximum alpha value at each pixel.
  /// Both masks must have the same dimensions and bounds.
  MaskData mergeMax(MaskData other) {
    assert(width == other.width && height == other.height);
    final result = Float32List(pixels.length);
    for (int i = 0; i < pixels.length; i++) {
      result[i] = math.max(pixels[i], other.pixels[i]);
    }
    return MaskData(width: width, height: height, pixels: result, bounds: bounds);
  }

  double valueAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return pixels[y * width + x];
  }

  /// Compute axis-aligned bounding rect of non-zero mask pixels.
  MaskBounds computeTightBounds() {
    int minX = width, minY = height, maxX = 0, maxY = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] > 0.01) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (minX > maxX) return MaskBounds.zero;
    return MaskBounds(
      left: bounds.left + minX,
      top: bounds.top + minY,
      right: bounds.left + maxX + 1,
      bottom: bounds.top + maxY + 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'width': width,
        'height': height,
        'pixels': pixels.toList(),
        'bounds': bounds.toJson(),
      };

  factory MaskData.fromJson(Map<String, dynamic> json) {
    final raw = List<double>.from(json['pixels'] as List);
    return MaskData(
      width: json['width'] as int,
      height: json['height'] as int,
      pixels: Float32List.fromList(raw),
      bounds: MaskBounds.fromJson(json['bounds'] as Map<String, dynamic>),
    );
  }
}

/// Integer pixel-space bounding box within the source image.
@immutable
class MaskBounds {
  final int left;
  final int top;
  final int right;
  final int bottom;

  const MaskBounds({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  static const MaskBounds zero = MaskBounds(left: 0, top: 0, right: 0, bottom: 0);

  int get width => right - left;
  int get height => bottom - top;
  bool get isEmpty => width <= 0 || height <= 0;

  MaskBounds clampTo(int imgWidth, int imgHeight) => MaskBounds(
        left: left.clamp(0, imgWidth),
        top: top.clamp(0, imgHeight),
        right: right.clamp(0, imgWidth),
        bottom: bottom.clamp(0, imgHeight),
      );

  /// Expand bounds by [margin] pixels in all directions.
  MaskBounds expand(int margin) => MaskBounds(
        left: left - margin,
        top: top - margin,
        right: right + margin,
        bottom: bottom + margin,
      );

  Map<String, dynamic> toJson() =>
      {'left': left, 'top': top, 'right': right, 'bottom': bottom};

  factory MaskBounds.fromJson(Map<String, dynamic> json) => MaskBounds(
        left: json['left'] as int,
        top: json['top'] as int,
        right: json['right'] as int,
        bottom: json['bottom'] as int,
      );

  @override
  String toString() => 'MaskBounds($left, $top → $right, $bottom)';
}
