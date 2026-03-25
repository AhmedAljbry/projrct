import 'dart:typed_data';
import 'package:meta/meta.dart';
import 'package:untitled2/vv/blemish_operation.dart';
import 'package:untitled2/vv/healing_region.dart';


/// Quality mode for the healing engine.
enum EngineQualityMode {
  /// Fast approximate healing — used for interactive preview.
  /// Reduced search radius, lower candidate count.
  preview,

  /// Full quality — used for final export apply.
  /// Larger search area, more candidates, better blending.
  finalQuality,
}

/// Result wrapper from the engine, carrying either a success or failure.
@immutable
class EngineResult {
  final HealedRegion? healed;
  final EngineError? error;

  const EngineResult.success(HealedRegion this.healed) : error = null;
  const EngineResult.failure(EngineError this.error) : healed = null;

  bool get isSuccess => healed != null;
  bool get isFailure => error != null;
}

/// Structured engine error.
@immutable
class EngineError {
  final String code;
  final String message;
  final Object? cause;

  const EngineError({required this.code, required this.message, this.cause});

  @override
  String toString() => 'EngineError[$code]: $message';
}

/// Abstract contract for a blemish removal engine.
/// Implementations may be pure-Dart, FFI-based, or platform channel-backed.
abstract class BlemishRemovalEngine {
  /// Human-readable name for this engine (for diagnostics/logging).
  String get engineName;

  /// Whether this engine supports async off-thread processing.
  bool get supportsIsolateProcessing;

  /// Whether this engine is available in the current environment.
  Future<bool> checkAvailability();

  /// Perform blemish healing for a single [operation] on [imagePixels].
  ///
  /// [imagePixels]: Full-resolution RGBA pixel buffer.
  /// [imageWidth], [imageHeight]: Source image dimensions.
  /// [operation]: The blemish operation to apply.
  /// [mode]: Preview or final quality.
  ///
  /// Returns an [EngineResult] with the healed region or an error.
  Future<EngineResult> heal({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required BlemishOperation operation,
    EngineQualityMode mode = EngineQualityMode.preview,
  });

  /// Apply multiple operations sequentially to produce a final output buffer.
  /// Returns the full modified RGBA pixel buffer.
  Future<Uint8List> applyAll({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required List<BlemishOperation> operations,
    EngineQualityMode mode = EngineQualityMode.finalQuality,
    void Function(int completed, int total)? onProgress,
  });

  /// Dispose engine resources. Must be called when the session ends.
  Future<void> dispose();
}

/// Adapter interface for a native (C++/OpenCV) engine backend.
/// Implementations should wrap platform channels or FFI calls.
abstract class NativeBlemishEngineAdapter extends BlemishRemovalEngine {
  /// Load and initialise the native library.
  Future<void> initialise();

  /// Check native library version compatibility.
  Future<String> nativeVersion();

  /// Transfer image data to native memory.
  Future<void> loadImage(Uint8List pixels, int width, int height);

  /// Release native image buffer.
  Future<void> unloadImage();
}
