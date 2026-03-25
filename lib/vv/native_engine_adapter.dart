import 'dart:typed_data';

import 'package:untitled2/vv/blemish_operation.dart';

import 'blemish_removal_engine.dart';

/// Stub adapter that will eventually delegate to a native C++/OpenCV engine
/// via platform channels or dart:ffi.
///
/// Current status: NOT IMPLEMENTED — falls back to the Dart baseline engine.
///
/// Integration roadmap:
///  1. iOS: Implement BlemishEnginePlugin in Swift wrapping OpenCV inpaint/seamlessClone
///  2. Android: Implement BlemishEnginePlugin in Kotlin/JNI wrapping OpenCV
///  3. Replace platform channel stubs below with real MethodChannel calls
///  4. Optionally implement direct FFI via `dart:ffi` + shared C++ library
///
/// OpenCV methods to integrate:
///  - cv::inpaint (TELEA or NAVIER_STOKES) for full inpainting
///  - cv::seamlessClone (NORMAL_CLONE or MIXED_CLONE) for patch blending
///  - PatchMatch algorithm for high-quality texture synthesis
class NativeOpenCvEngineAdapter extends NativeBlemishEngineAdapter {
  static const _channelName = 'pro.filterstudio/blemish_engine';

  bool _initialised = false;

  @override
  String get engineName => 'OpenCV Native Engine (stub)';

  @override
  bool get supportsIsolateProcessing => false; // native runs on its own thread

  @override
  Future<void> initialise() async {
    // TODO: Invoke platform channel to load OpenCV shared library.
    // MethodChannel(_channelName).invokeMethod('initialise');
    _initialised = false; // mark as stub
  }

  @override
  Future<String> nativeVersion() async {
    // TODO: MethodChannel(_channelName).invokeMethod('version')
    return 'stub-0.0.0';
  }

  @override
  Future<bool> checkAvailability() async => _initialised;

  @override
  Future<void> loadImage(Uint8List pixels, int width, int height) async {
    // TODO: Transfer pixels to native side via platform channel or FFI.
    // Large pixel buffers should use TransferableTypedData or shared memory.
    throw UnimplementedError('NativeOpenCvEngineAdapter.loadImage not implemented');
  }

  @override
  Future<void> unloadImage() async {
    throw UnimplementedError('NativeOpenCvEngineAdapter.unloadImage not implemented');
  }

  @override
  Future<EngineResult> heal({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required BlemishOperation operation,
    EngineQualityMode mode = EngineQualityMode.preview,
  }) async {
    throw UnimplementedError(
        'NativeOpenCvEngineAdapter is a stub. Use DartBlemishEngine instead.');
  }

  @override
  Future<Uint8List> applyAll({
    required Uint8List imagePixels,
    required int imageWidth,
    required int imageHeight,
    required List<BlemishOperation> operations,
    EngineQualityMode mode = EngineQualityMode.finalQuality,
    void Function(int completed, int total)? onProgress,
  }) async {
    throw UnimplementedError(
        'NativeOpenCvEngineAdapter is a stub. Use DartBlemishEngine instead.');
  }

  @override
  Future<void> dispose() async {
    // TODO: release native memory
  }
}

/// Factory that selects the best available engine at runtime.
/// Priority: Native > Dart fallback.
class BlemishEngineFactory {
  static Future<BlemishRemovalEngine> create() async {
    final native = NativeOpenCvEngineAdapter();
    await native.initialise();
    if (await native.checkAvailability()) {
      return native;
    }
    // Fall back to the pure-Dart baseline engine.
    // Import lazily to avoid circular dependencies.
    // ignore: avoid_dynamic_calls
    final dartEngine = await _createDartEngine();
    return dartEngine;
  }

  static Future<BlemishRemovalEngine> _createDartEngine() async {
    // Deferred import to keep this file dependency-light.
    // In your project: import '../baseline/dart_blemish_engine.dart';
    throw UnimplementedError(
        'Wire DartBlemishEngine here: return DartBlemishEngine()');
  }
}
