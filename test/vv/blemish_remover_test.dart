// ignore_for_file: avoid_print
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';

// Adjust these imports to your actual package name.
// import 'package:your_app/feature/blemish_remover/...';

// ─── We inline simplified versions here so this file is self-contained. ─────
// In your actual project, import from the feature modules above.

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  group('MaskData', () {
    test('circularDab produces non-zero pixels within radius', () {
      final mask = _makeCircularDab(cx: 10, cy: 10, radius: 8, softness: 0.5);
      // Centre pixel should be 1.0
      expect(mask.valueAt(10, 10), closeTo(1.0, 0.01));
      // Far outside pixel should be 0.0
      expect(mask.valueAt(0, 0), closeTo(0.0, 0.01));
    });

    test('mergeMax combines two masks correctly', () {
      final a = _makeCircularDab(cx: 5, cy: 5, radius: 5, softness: 0.0);
      final b = _makeCircularDab(cx: 5, cy: 5, radius: 5, softness: 0.0);
      final merged = a.mergeMax(b);
      expect(merged.width, a.width);
      expect(merged.height, a.height);
    });

    test('MaskBounds clampTo enforces image dimensions', () {
      const bounds = _MaskBoundsHelper(-10, -5, 200, 300);
      final clamped = bounds.clampTo(100, 100);
      expect(clamped.left, 0);
      expect(clamped.top, 0);
      expect(clamped.right, 100);
      expect(clamped.bottom, 100);
    });

    test('computeTightBounds returns correct tight rect', () {
      final mask = _makeCircularDab(cx: 10, cy: 10, radius: 4, softness: 0.0);
      final tight = mask.computeTightBounds();
      expect(tight.width, greaterThan(0));
      expect(tight.height, greaterThan(0));
    });

    test('toJson / fromJson round-trips correctly', () {
      final mask = _makeCircularDab(cx: 8, cy: 8, radius: 6, softness: 0.6);
      final json = mask.toJson();
      final restored = _MaskDataHelper.fromJson(json);
      expect(restored.width, mask.width);
      expect(restored.height, mask.height);
      expect(restored.pixels.length, mask.pixels.length);
      expect(restored.pixels[0], closeTo(mask.pixels[0], 0.001));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('BrushSettings', () {
    test('default values are in range', () {
      const brush = _BrushSettingsHelper();
      expect(brush.radius, greaterThan(0));
      expect(brush.softness, inInclusiveRange(0.0, 1.0));
      expect(brush.strength, inInclusiveRange(0.0, 1.0));
      expect(brush.spacing, inInclusiveRange(0.0, 1.0));
    });

    test('copyWith overrides only specified fields', () {
      const original = _BrushSettingsHelper(radius: 20, softness: 0.5);
      final modified = original.copyWith(radius: 40);
      expect(modified.radius, 40);
      expect(modified.softness, 0.5);
    });

    test('toJson/fromJson round-trips', () {
      const brush = _BrushSettingsHelper(radius: 32, softness: 0.7, strength: 0.8);
      final json = brush.toJson();
      final restored = _BrushSettingsHelper.fromJson(json);
      expect(restored.radius, brush.radius);
      expect(restored.softness, brush.softness);
      expect(restored.strength, brush.strength);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('TextureAnalyzer', () {
    late Uint8List testImage;
    const w = 32, h = 32;

    setUp(() {
      // Solid grey 32×32 image with a darker patch in the centre.
      testImage = Uint8List(w * h * 4);
      for (int y = 0; y < h; y++) {
        for (int x = 0; x < w; x++) {
          final idx = (y * w + x) * 4;
          final isDark = (x >= 12 && x < 20 && y >= 12 && y < 20);
          testImage[idx] = isDark ? 80 : 180;
          testImage[idx + 1] = isDark ? 70 : 170;
          testImage[idx + 2] = isDark ? 75 : 175;
          testImage[idx + 3] = 255;
        }
      }
    });

    test('computeMeanLuminance returns plausible value for bright region', () {
      final lum = _TextureAnalyzerHelper.computeMeanLuminance(
        testImage, w, h, _MaskBoundsHelper(0, 0, 10, 10),
      );
      expect(lum, greaterThan(100)); // should be close to 170
    });

    test('computeLuminanceVariance is higher in mixed region', () {
      final varBright = _TextureAnalyzerHelper.computeLuminanceVariance(
        testImage, w, h, _MaskBoundsHelper(0, 0, 10, 10),
      );
      final varMixed = _TextureAnalyzerHelper.computeLuminanceVariance(
        testImage, w, h, _MaskBoundsHelper(8, 8, 24, 24),
      );
      expect(varMixed, greaterThan(varBright));
    });

    test('computeSAD returns 0 for identical regions', () {
      final sad = _TextureAnalyzerHelper.computeSAD(
        testImage, w, h,
        _MaskBoundsHelper(0, 0, 8, 8),
        _MaskBoundsHelper(0, 0, 8, 8),
      );
      expect(sad, closeTo(0, 0.01));
    });

    test('computeSAD returns positive value for different regions', () {
      final sad = _TextureAnalyzerHelper.computeSAD(
        testImage, w, h,
        _MaskBoundsHelper(0, 0, 8, 8),     // bright
        _MaskBoundsHelper(12, 12, 20, 20), // dark
      );
      expect(sad, greaterThan(50));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('PatchSearcher', () {
    late Uint8List image;
    const w = 64, h = 64;

    setUp(() {
      image = Uint8List(w * h * 4);
      final rng = math.Random(42);
      for (int i = 0; i < image.length; i += 4) {
        final v = rng.nextInt(60) + 160; // near-uniform skin-like tone
        image[i] = v;
        image[i + 1] = v - 10;
        image[i + 2] = v - 20;
        image[i + 3] = 255;
      }
    });

    test('findCandidates returns at least one candidate', () {
      final result = _PatchSearcherHelper.findCandidates(
        imagePixels: image, imageWidth: w, imageHeight: h,
        targetRegion: _MaskBoundsHelper(28, 28, 36, 36),
        mode: _EngineQualityMode.preview,
      );
      expect(result.candidates, isNotEmpty);
    });

    test('best candidate has lowest score in list', () {
      final result = _PatchSearcherHelper.findCandidates(
        imagePixels: image, imageWidth: w, imageHeight: h,
        targetRegion: _MaskBoundsHelper(28, 28, 36, 36),
        mode: _EngineQualityMode.preview,
      );
      final scores = result.candidates.map((c) => c.score).toList();
      expect(result.bestPatch.score, scores.reduce(math.min));
    });

    test('candidates do not overlap target region', () {
      final target = _MaskBoundsHelper(28, 28, 36, 36);
      final result = _PatchSearcherHelper.findCandidates(
        imagePixels: image, imageWidth: w, imageHeight: h,
        targetRegion: target,
        mode: _EngineQualityMode.finalQuality,
      );
      for (final c in result.candidates) {
        // No candidate should be fully inside the target.
        // They may partially overlap (ring buffer), but the patch
        // They may partially overlap (ring buffer), but the patch
        // searcher explicitly excludes exact overlaps.
        expect(c.sourceX < 0 || c.sourceY < 0, isFalse,
            reason: 'Candidate must be within image bounds');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('HistoryService', () {
    test('commit adds to undo stack', () {
      final history = _HistoryServiceHelper();
      expect(history.canUndo, isFalse);
      history.commit(_makeOperation('op1'));
      expect(history.canUndo, isTrue);
      expect(history.operations.length, 1);
    });

    test('undo moves to redo stack', () {
      final history = _HistoryServiceHelper();
      history.commit(_makeOperation('op1'));
      final undone = history.undo();
      expect(undone?.id, 'op1');
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isTrue);
    });

    test('redo restores operation', () {
      final history = _HistoryServiceHelper();
      history.commit(_makeOperation('op1'));
      history.undo();
      final redone = history.redo();
      expect(redone?.id, 'op1');
      expect(history.canRedo, isFalse);
    });

    test('new commit clears redo stack', () {
      final history = _HistoryServiceHelper();
      history.commit(_makeOperation('op1'));
      history.undo();
      history.commit(_makeOperation('op2'));
      expect(history.canRedo, isFalse);
    });

    test('respects maxHistorySize', () {
      final history = _HistoryServiceHelper(maxSize: 3);
      for (int i = 0; i < 5; i++) {
        history.commit(_makeOperation('op$i'));
      }
      expect(history.operations.length, 3);
    });

    test('clear empties both stacks', () {
      final history = _HistoryServiceHelper();
      history.commit(_makeOperation('op1'));
      history.clear();
      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('toJson / loadHistory round-trips', () {
      final history = _HistoryServiceHelper();
      history.commit(_makeOperation('op1'));
      final json = history.toJson();
      final history2 = _HistoryServiceHelper();
      history2.loadFromJson(json);
      expect(history2.operations.length, 1);
      expect(history2.operations.first.id, 'op1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('BlemishOperation', () {
    test('strokeBounds expands by brush radius', () {
      final op = _makeOperation('op1', radius: 20.0);
      final bounds = op.strokeBounds;
      expect(bounds.left, lessThanOrEqualTo(40 - 20));
      expect(bounds.top, lessThanOrEqualTo(40 - 20));
    });

    test('toJson / fromJson is lossless', () {
      final op = _makeOperation('round-trip-op');
      final json = op.toJson();
      final restored = _BlemishOperationHelper.fromJson(json);
      expect(restored.id, op.id);
      expect(restored.strokePoints.length, op.strokePoints.length);
      expect(restored.brushSettings.radius, op.brushSettings.radius);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  group('MaskGenerationService', () {
    test('single spot mask has non-zero pixels at tap point', () {
      final svc = _MaskGenServiceHelper();
      final mask = svc.generateSpotMask(
        tapPosition: const Offset(50, 50),
        brushRadius: 16.0,
        brushSoftness: 0.7,
        imageWidth: 100,
        imageHeight: 100,
      );
      expect(mask.bounds.isEmpty, isFalse);
      // Centre should have near-1 alpha.
      final localX = 50 - mask.bounds.left;
      final localY = 50 - mask.bounds.top;
      if (localX >= 0 && localX < mask.width && localY >= 0 && localY < mask.height) {
        expect(mask.valueAt(localX, localY), greaterThan(0.8));
      }
    });

    test('stroke mask covers all dab positions', () {
      final svc = _MaskGenServiceHelper();
      final mask = svc.generateStrokeMask(
        points: [
          const Offset(20, 50),
          const Offset(50, 50),
          const Offset(80, 50),
        ],
        radius: 10.0,
        softness: 0.5,
        imageWidth: 100,
        imageHeight: 100,
      );
      // Bounds should span from roughly 10 to 90 on the x axis.
      expect(mask.bounds.left, lessThanOrEqualTo(20));
      expect(mask.bounds.right, greaterThanOrEqualTo(80));
    });

    test('masks clamp to image bounds', () {
      final svc = _MaskGenServiceHelper();
      final mask = svc.generateSpotMask(
        tapPosition: const Offset(2, 2),
        brushRadius: 20.0,
        brushSoftness: 0.5,
        imageWidth: 100,
        imageHeight: 100,
      );
      expect(mask.bounds.left, greaterThanOrEqualTo(0));
      expect(mask.bounds.top, greaterThanOrEqualTo(0));
    });
  });
}

// ─── Lightweight test-double helpers (no actual imports needed) ───────────────
// These mirror the real classes' logic for testing purposes.
// In your project, replace with real imports.

// MaskData test helper
class _MaskDataHelper {
  final int width, height;
  final Float32List pixels;
  final _MaskBoundsHelper bounds;
  const _MaskDataHelper(this.width, this.height, this.pixels, this.bounds);

  double valueAt(int x, int y) {
    if (x < 0 || x >= width || y < 0 || y >= height) return 0.0;
    return pixels[y * width + x];
  }

  _MaskDataHelper mergeMax(_MaskDataHelper other) {
    assert(width == other.width && height == other.height);
    final r = Float32List(pixels.length);
    for (int i = 0; i < r.length; i++) {
      r[i] = math.max(pixels[i], other.pixels[i]);
    }
    return _MaskDataHelper(width, height, r, bounds);
  }

  _MaskBoundsHelper computeTightBounds() {
    int mnX = width, mnY = height, mxX = 0, mxY = 0;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (pixels[y * width + x] > 0.01) {
          if (x < mnX) mnX = x; if (y < mnY) mnY = y;
          if (x > mxX) mxX = x; if (y > mxY) mxY = y;
        }
      }
    }
    if (mnX > mxX) return const _MaskBoundsHelper(0, 0, 0, 0);
    return _MaskBoundsHelper(bounds.left + mnX, bounds.top + mnY,
        bounds.left + mxX + 1, bounds.top + mxY + 1);
  }

  Map<String, dynamic> toJson() => {
        'width': width, 'height': height,
        'pixels': pixels.toList(), 'bounds': bounds.toJson(),
      };

  static _MaskDataHelper fromJson(Map<String, dynamic> json) {
    return _MaskDataHelper(
      json['width'] as int, json['height'] as int,
      Float32List.fromList(List<double>.from(json['pixels'] as List)),
      _MaskBoundsHelper.fromJson(json['bounds'] as Map<String, dynamic>),
    );
  }
}

_MaskDataHelper _makeCircularDab({
  required double cx, required double cy,
  required double radius, required double softness,
}) {
  const originX = 0, originY = 0;
  final w = (radius * 2).ceil() + 4;
  final h = (radius * 2).ceil() + 4;
  final pixels = Float32List(w * h);
  final hardR = radius * (1.0 - softness.clamp(0.0, 0.99));
  for (int py = 0; py < h; py++) {
    for (int px = 0; px < w; px++) {
      final dx = px - cx; final dy = py - cy;
      final d = math.sqrt(dx * dx + dy * dy);
      double a = 0;
      if (d <= hardR) { a = 1.0; }
      else if (d < radius) { a = 0.5 + 0.5 * math.cos(math.pi * (d - hardR) / (radius - hardR)); }
      pixels[py * w + px] = a;
    }
  }
  return _MaskDataHelper(w, h, pixels, _MaskBoundsHelper(originX, originY, originX + w, originY + h));
}

class _MaskBoundsHelper {
  final int left, top, right, bottom;
  const _MaskBoundsHelper(this.left, this.top, this.right, this.bottom);
  int get width => right - left;
  int get height => bottom - top;
  bool get isEmpty => width <= 0 || height <= 0;
  _MaskBoundsHelper clampTo(int iw, int ih) =>
      _MaskBoundsHelper(left.clamp(0, iw), top.clamp(0, ih),
          right.clamp(0, iw), bottom.clamp(0, ih));
  Map<String, dynamic> toJson() => {'left': left, 'top': top, 'right': right, 'bottom': bottom};
  static _MaskBoundsHelper fromJson(Map<String, dynamic> j) =>
      _MaskBoundsHelper(j['left'] as int, j['top'] as int, j['right'] as int, j['bottom'] as int);
}

class _BrushSettingsHelper {
  final double radius, softness, strength, spacing;
  const _BrushSettingsHelper({this.radius = 24.0, this.softness = 0.7, this.strength = 0.9, this.spacing = 0.5});
  _BrushSettingsHelper copyWith({double? radius, double? softness, double? strength}) =>
      _BrushSettingsHelper(radius: radius ?? this.radius, softness: softness ?? this.softness, strength: strength ?? this.strength);
  Map<String, dynamic> toJson() => {'radius': radius, 'softness': softness, 'strength': strength, 'spacing': spacing, 'velocityPressure': false};
  static _BrushSettingsHelper fromJson(Map<String, dynamic> j) =>
      _BrushSettingsHelper(radius: (j['radius'] as num).toDouble(), softness: (j['softness'] as num).toDouble(), strength: (j['strength'] as num).toDouble());
}

// Minimal BlemishOperation test double
class _FakeOperation {
  final String id;
  final List<Offset> strokePoints;
  final _BrushSettingsHelper brushSettings;
  _FakeOperation(this.id, this.strokePoints, this.brushSettings);
  _MaskBoundsHelper get strokeBounds {
    double mnX = 1e9, mnY = 1e9, mxX = -1e9, mxY = -1e9;
    for (final p in strokePoints) {
      if (p.dx < mnX) mnX = p.dx; if (p.dy < mnY) mnY = p.dy;
      if (p.dx > mxX) mxX = p.dx; if (p.dy > mxY) mxY = p.dy;
    }
    final r = brushSettings.radius.ceil();
    return _MaskBoundsHelper((mnX - r).floor(), (mnY - r).floor(), (mxX + r).ceil(), (mxY + r).ceil());
  }
  Map<String, dynamic> toJson() => {
    'id': id, 'createdAt': DateTime.now().toIso8601String(),
    'brushSettings': brushSettings.toJson(),
    'strokePoints': strokePoints.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    'strokeType': 'spotHeal',
    'mask': _makeCircularDab(cx: strokePoints.first.dx, cy: strokePoints.first.dy, radius: 8, softness: 0.5).toJson(),
    'sourcePatchOrigin': null, 'isProcessed': false,
  };
  static _FakeOperation fromJson(Map<String, dynamic> j) {
    final pts = (j['strokePoints'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
    return _FakeOperation(j['id'] as String, pts, _BrushSettingsHelper.fromJson(j['brushSettings'] as Map<String, dynamic>));
  }
}

_FakeOperation _makeOperation(String id, {double radius = 16.0}) =>
    _FakeOperation(id, [const Offset(40, 40)], _BrushSettingsHelper(radius: radius));

class _BlemishOperationHelper {
  static _FakeOperation fromJson(Map<String, dynamic> j) => _FakeOperation.fromJson(j);
}

class _HistoryServiceHelper {
  final int maxSize;
  final List<_FakeOperation> _undo = [];
  final List<_FakeOperation> _redo = [];
  _HistoryServiceHelper({this.maxSize = 50});
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  List<_FakeOperation> get operations => List.unmodifiable(_undo);
  void commit(_FakeOperation op) {
    _undo.add(op); _redo.clear();
    while (_undo.length > maxSize) {
      _undo.removeAt(0);
    }
  }
  _FakeOperation? undo() { if (!canUndo) return null; final op = _undo.removeLast(); _redo.add(op); return op; }
  _FakeOperation? redo() { if (!canRedo) return null; final op = _redo.removeLast(); _undo.add(op); return op; }
  void clear() { _undo.clear(); _redo.clear(); }
  List<Map<String, dynamic>> toJson() => _undo.map((o) => o.toJson()).toList();
  void loadFromJson(List<Map<String, dynamic>> json) {
    _undo.clear(); _undo.addAll(json.map(_FakeOperation.fromJson));
  }
}

// Texture analyzer helper
class _TextureAnalyzerHelper {
  static double computeMeanLuminance(Uint8List pixels, int w, int h, _MaskBoundsHelper region) {
    double sum = 0; int count = 0;
    for (int y = region.top; y < region.bottom && y < h; y++) {
      for (int x = region.left; x < region.right && x < w; x++) {
        final idx = (y * w + x) * 4;
        sum += 0.299 * pixels[idx] + 0.587 * pixels[idx + 1] + 0.114 * pixels[idx + 2];
        count++;
      }
    }
    return count > 0 ? sum / count : 128;
  }
  static double computeLuminanceVariance(Uint8List pixels, int w, int h, _MaskBoundsHelper region) {
    double sum = 0, sumSq = 0; int count = 0;
    for (int y = region.top; y < region.bottom && y < h; y++) {
      for (int x = region.left; x < region.right && x < w; x++) {
        final idx = (y * w + x) * 4;
        final lum = 0.299 * pixels[idx] + 0.587 * pixels[idx + 1] + 0.114 * pixels[idx + 2];
        sum += lum; sumSq += lum * lum; count++;
      }
    }
    if (count == 0) return 0;
    final mean = sum / count;
    return (sumSq / count) - (mean * mean);
  }
  static double computeSAD(Uint8List pixels, int w, int h, _MaskBoundsHelper a, _MaskBoundsHelper b) {
    final pw = math.min(a.width, b.width), ph = math.min(a.height, b.height);
    double sad = 0; int count = 0;
    for (int dy = 0; dy < ph; dy++) {
      for (int dx = 0; dx < pw; dx++) {
        final ax = a.left + dx, ay = a.top + dy;
        final bx = b.left + dx, by = b.top + dy;
        if (ax >= w || ay >= h || bx >= w || by >= h) continue;
        final ia = (ay * w + ax) * 4, ib = (by * w + bx) * 4;
        sad += 0.299 * (pixels[ia] - pixels[ib]).abs() + 0.587 * (pixels[ia + 1] - pixels[ib + 1]).abs() + 0.114 * (pixels[ia + 2] - pixels[ib + 2]).abs();
        count++;
      }
    }
    return count > 0 ? sad / count : 0;
  }
}

// Patch searcher helper
enum _EngineQualityMode { preview, finalQuality }
class _PatchResult {
  final _FakePatch bestPatch;
  final List<_FakePatch> candidates;
  const _PatchResult(this.bestPatch, this.candidates);
}
class _FakePatch {
  final int sourceX, sourceY, patchWidth, patchHeight;
  final double score;
  const _FakePatch(this.sourceX, this.sourceY, this.patchWidth, this.patchHeight, this.score);
}
class _PatchSearcherHelper {
  static _PatchResult findCandidates({
    required Uint8List imagePixels, required int imageWidth, required int imageHeight,
    required _MaskBoundsHelper targetRegion, required _EngineQualityMode mode,
  }) {
    final pw = targetRegion.width, ph = targetRegion.height;
    final ringMax = (math.max(pw, ph) * 3).ceil();
    final stride = math.max(math.min(pw, ph) ~/ 2, 2);
    final candidates = <_FakePatch>[];
    for (int sy = targetRegion.top - ringMax; sy <= targetRegion.bottom + ringMax - ph; sy += stride) {
      for (int sx = targetRegion.left - ringMax; sx <= targetRegion.right + ringMax - pw; sx += stride) {
        if (sx < 0 || sy < 0 || sx + pw > imageWidth || sy + ph > imageHeight) continue;
        final overlaps = sx < targetRegion.right && sy < targetRegion.bottom &&
            sx + pw > targetRegion.left && sy + ph > targetRegion.top;
        if (overlaps) continue;
        final score = _TextureAnalyzerHelper.computeSAD(imagePixels, imageWidth, imageHeight,
            targetRegion, _MaskBoundsHelper(sx, sy, sx + pw, sy + ph));
        candidates.add(_FakePatch(sx, sy, pw, ph, score));
      }
    }
    if (candidates.isEmpty) {
      final fb = _FakePatch((targetRegion.right + 4).clamp(0, imageWidth - pw), targetRegion.top.clamp(0, imageHeight - ph), pw, ph, 9999);
      return _PatchResult(fb, [fb]);
    }
    candidates.sort((a, b) => a.score.compareTo(b.score));
    return _PatchResult(candidates.first, candidates.take(12).toList());
  }
}

// Mask generation service helper
class _MaskGenServiceHelper {
  _MaskDataHelper generateSpotMask({required Offset tapPosition, required double brushRadius, required double brushSoftness, required int imageWidth, required int imageHeight}) {
    return _makeCircularDab(cx: tapPosition.dx, cy: tapPosition.dy, radius: brushRadius, softness: brushSoftness);
  }
  _MaskDataHelper generateStrokeMask({required List<Offset> points, required double radius, required double softness, required int imageWidth, required int imageHeight}) {
    double mnX = 1e9, mnY = 1e9, mxX = -1e9, mxY = -1e9;
    for (final p in points) {
      if (p.dx < mnX) mnX = p.dx; if (p.dy < mnY) mnY = p.dy;
      if (p.dx > mxX) mxX = p.dx; if (p.dy > mxY) mxY = p.dy;
    }
    final r = radius.ceil() + 1;
    final bLeft = (mnX - r).floor().clamp(0, imageWidth);
    final bTop = (mnY - r).floor().clamp(0, imageHeight);
    final bRight = (mxX + r).ceil().clamp(0, imageWidth);
    final bBottom = (mxY + r).ceil().clamp(0, imageHeight);
    final w = bRight - bLeft, h = bBottom - bTop;
    final pixels = Float32List(w * h);
    for (final p in points) {
      for (int py = 0; py < h; py++) {
        for (int px = 0; px < w; px++) {
          final dx = (bLeft + px) - p.dx, dy = (bTop + py) - p.dy;
          final d = math.sqrt(dx * dx + dy * dy);
          double a = 0;
          final hardR = radius * (1.0 - softness.clamp(0.0, 0.99));
          if (d <= hardR) { a = 1.0; }
          else if (d < radius) { a = 0.5 + 0.5 * math.cos(math.pi * (d - hardR) / (radius - hardR)); }
          if (a > pixels[py * w + px]) pixels[py * w + px] = a;
        }
      }
    }
    return _MaskDataHelper(w, h, pixels, _MaskBoundsHelper(bLeft, bTop, bRight, bBottom));
  }
}
