# ═══════════════════════════════════════════════════════════════════════════════
# BLEMISH REMOVER — COMPLETE INTEGRATION GUIDE
# ═══════════════════════════════════════════════════════════════════════════════

## 1. ARCHITECTURE SUMMARY
─────────────────────────────────────────────────────────────────────────────────
The blemish remover is a self-contained feature module with strict layer separation:

  ┌──────────────────────────────────────────────────────────────┐
  │  PRESENTATION  (screens / widgets / painters)                │
  │   BlemishRemoverScreen → BlemishEditCanvas → BrushControlPanel│
  ├──────────────────────────────────────────────────────────────┤
  │  STATE  (BLoC / Cubit)                                       │
  │   BlemishCubit  ←→  BlemishState                            │
  ├──────────────────────────────────────────────────────────────┤
  │  DOMAIN  (use cases / entities)                              │
  │   BlemishOperation, MaskData, BrushSettings, HealingRegion  │
  │   ApplyBlemishOperationUseCase, BuildBlemishOperationUseCase │
  ├──────────────────────────────────────────────────────────────┤
  │  SERVICES                                                    │
  │   MaskGenerationService (Catmull-Rom + dab stamping)        │
  │   BrushInteractionService (touch → image coords)            │
  │   HistoryService (undo/redo stacks)                         │
  │   ExportService (final PNG render)                          │
  ├──────────────────────────────────────────────────────────────┤
  │  ENGINE                                                      │
  │   BlemishRemovalEngine (interface)                          │
  │   DartBlemishEngine (baseline implementation)               │
  │   EngineIsolateWorker (off-thread dispatch)                 │
  │   NativeOpenCvEngineAdapter (stub for future backend)       │
  ├──────────────────────────────────────────────────────────────┤
  │  DATA  (repositories / serialization)                       │
  │   BlemishSessionSerializer (JSON save/load)                 │
  │   FileBlemishSessionRepository (disk persistence)           │
  └──────────────────────────────────────────────────────────────┘

## 2. FOLDER TREE
─────────────────────────────────────────────────────────────────────────────────
lib/
└── feature/
    └── blemish_remover/
        ├── data/
        │   ├── repositories/
        │   │   └── blemish_session_repository.dart
        │   └── serialization/
        │       └── blemish_session_serializer.dart
        ├── domain/
        │   ├── entities/
        │   │   ├── blemish_operation.dart
        │   │   ├── brush_settings.dart
        │   │   ├── healing_region.dart
        │   │   ├── mask_data.dart
        │   │   └── patch_candidate.dart
        │   └── usecases/
        │       └── blemish_usecases.dart
        ├── engine/
        │   ├── abstractions/
        │   │   ├── blemish_removal_engine.dart
        │   │   └── native_engine_adapter.dart
        │   ├── baseline/
        │   │   ├── dart_blemish_engine.dart
        │   │   ├── patch_blender.dart
        │   │   ├── patch_searcher.dart
        │   │   └── texture_analyzer.dart
        │   └── isolate/
        │       └── engine_isolate_worker.dart
        ├── presentation/
        │   ├── screens/
        │   │   └── blemish_remover_screen.dart
        │   └── widgets/
        │       ├── blemish_canvas_painter.dart
        │       ├── blemish_edit_canvas.dart
        │       ├── blemish_ui_widgets.dart
        │       └── brush_control_panel.dart
        ├── services/
        │   ├── brush_interaction_service.dart
        │   ├── export_service.dart
        │   ├── history_service.dart
        │   └── mask_generation_service.dart
        ├── state/
        │   ├── blemish_cubit.dart
        │   └── blemish_state.dart
        └── tests/
            └── blemish_remover_test.dart


## 3. PUBSPEC ADDITIONS
─────────────────────────────────────────────────────────────────────────────────

Add to your pubspec.yaml:

```yaml
dependencies:
  flutter:
    sdk: flutter

  # State management
  flutter_bloc: ^8.1.3
  bloc: ^8.1.2

  # Immutable value types (optional but recommended)
  meta: ^1.9.1

  # Functional error handling (optional)
  # dartz: ^0.10.1  # if you prefer Either<L,R> instead of EngineResult

dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.1.4
  mocktail: ^1.0.1
```

No native plugin dependencies are required for the baseline Dart engine.
The OpenCV native backend will require:
  - opencv_flutter: (custom or community plugin)  OR
  - Direct platform channel plugin in ios/ and android/


## 4. SCREEN INTEGRATION
─────────────────────────────────────────────────────────────────────────────────

### 4a. Push from an existing editor screen

```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'feature/blemish_remover/presentation/screens/blemish_remover_screen.dart';

Future<void> openBlemishRemover(BuildContext context, ui.Image image) async {
  final result = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute(
      builder: (_) => BlemishRemoverScreen(
        sourceImage: image,
        onApply: (pngBytes) {
          Navigator.of(context).pop(pngBytes);
        },
        onCancel: () {
          Navigator.of(context).pop(null);
        },
      ),
    ),
  );

  if (result != null) {
    // result is the final PNG bytes with all blemishes removed.
    // Feed back into your editor pipeline.
    _handleExportedImage(result);
  }
}
```

### 4b. Loading a ui.Image from file / asset

```dart
Future<ui.Image> loadUiImageFromFile(String path) async {
  final bytes = await File(path).readAsBytes();
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  return frame.image;
}
```

### 4c. Loading from your existing editor's working image

If your editor already maintains a `ui.Image` or `Uint8List` representation,
pass it directly. No intermediate PNG encode/decode is required if you can
supply a `ui.Image` directly.


## 5. HOW THE PREVIEW PIPELINE WORKS
─────────────────────────────────────────────────────────────────────────────────

1. User touches canvas → `BlemishEditCanvas._onScaleUpdate` fires.
2. `BlemishCubit.onStrokeUpdate` converts canvas coords → image coords via
   `BrushInteractionService.canvasToImage`.
3. Active stroke points are emitted into state for real-time cursor overlay.
4. On `onStrokeEnd`:
   a. `MaskGenerationService.generateStrokeMask` runs Catmull-Rom interpolation
      on raw touch points, then stamps circular dabs with feather falloff.
   b. `BlemishOperation` is constructed with the mask.
   c. `EngineIsolateWorker.heal` is called with `EngineQualityMode.preview`.
   d. Inside the worker Isolate, `DartBlemishEngine.heal` runs:
      - `PatchSearcher.findCandidates` scans an annular ring with reduced
        search radius (preview tuning) and scores patches by feature distance
        + SAD (sum of absolute differences).
      - `PatchBlender.blend` composites the best patch using tone-shift
        correction and soft-mask alpha blending.
   e. Healed RGBA pixels are returned to the main isolate.
   f. `BlemishCubit` writes them into `previewPixels` in state.
5. `BlemishEditCanvas._updatePreviewImage` decodes `previewPixels` into
   `ui.Image` via `decodeImageFromPixels`.
6. `BlemishCanvasPainter` renders the preview image on the next frame.

Latency budget (typical mobile):
  - Mask generation:       ~1–3 ms
  - Patch search preview:  ~5–20 ms (16px brush, 512px image)
  - Blend + edge smooth:   ~2–8 ms
  - Isolate round-trip:    ~3–5 ms overhead
  Total (preview mode):    ~10–35 ms per stroke end


## 6. HOW THE FINAL APPLY WORKS
─────────────────────────────────────────────────────────────────────────────────

1. User taps "Apply" → `BlemishCubit.exportImage()` is called.
2. `ExportService.export` is invoked with `EngineQualityMode.finalQuality`.
3. Source `ui.Image` is decoded to raw RGBA via `toByteData(rawRgba)`.
4. `EngineIsolateWorker.applyAll` dispatches all committed operations
   sequentially to `DartBlemishEngine.applyAll`, which:
   a. Uses a larger search ring (5× patch size vs 3× in preview).
   b. Samples more candidate patches (up to 40 vs 12).
   c. Applies edge smoothing via a boundary Gaussian pass.
5. Progress callbacks update `state.exportProgress` for the UI progress bar.
6. The processed RGBA buffer is re-encoded to PNG via `toByteData(png)`.
7. PNG bytes are returned to the caller's `onApply` callback.


## 7. HOW UNDO / REDO WORKS
─────────────────────────────────────────────────────────────────────────────────

Data model:
  - `HistoryService` maintains two `List<BlemishOperation>` stacks:
    `_undoStack` (committed ops) and `_redoStack` (undone ops).
  - All operations are stored as immutable value objects with full mask data,
    so replay is exact and deterministic.

Undo flow:
  1. `BlemishCubit.undo()` pops the last op from `_undoStack` into `_redoStack`.
  2. `_recomputePreview()` replays all remaining ops on the original source image
     using `EngineIsolateWorker.applyAll(preview mode)`.
  3. The rebuilt preview is emitted into state.

Redo flow:
  1. `BlemishCubit.redo()` pops from `_redoStack` back to `_undoStack`.
  2. Same `_recomputePreview()` replay.

Why replay instead of storing intermediate bitmaps:
  - Memory: each RGBA bitmap at 12MP = ~48 MB. Storing 50 history frames
    would require ~2.4 GB. Replay from ops is ~KB per operation.
  - Correctness: replay is deterministic and avoids drift.
  - Cost: preview replay at 1× scale is fast; production code may cache the
    last N preview bitmaps for instant undo feedback.


## 8. FUTURE NATIVE UPGRADE PATH
─────────────────────────────────────────────────────────────────────────────────

### 8a. OpenCV backend (recommended next step)

Implement `NativeOpenCvEngineAdapter` on both platforms:

iOS (Swift / Objective-C++):
```swift
// BlemishEnginePlugin.swift
import opencv2

@objc class BlemishEnginePlugin: NSObject, FlutterPlugin {
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "heal":
            let args = call.arguments as! [String: Any]
            // Decode pixels, bounds, mask from args
            // cv::inpaint(src, mask, dst, 3, cv::INPAINT_TELEA)
            // OR cv::seamlessClone(src, dst, mask, center, output, cv::NORMAL_CLONE)
            result(encodedOutput)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
```

Android (Kotlin / JNI):
```kotlin
class BlemishEnginePlugin : MethodCallHandler {
    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "heal" -> {
                // Mat src = ...; Mat mask = ...;
                // Photo.inpaint(src, mask, dst, 3, Photo.INPAINT_TELEA)
                result.success(encodedOutput)
            }
        }
    }
}
```

### 8b. PatchMatch C++ via dart:ffi

1. Implement `patchmatch.cpp` with `extern "C"` exported functions:
   ```c
   extern "C" {
     void* pm_init(uint8_t* pixels, int w, int h);
     void pm_heal(void* ctx, int x, int y, int w, int h,
                  uint8_t* maskPixels, uint8_t* outPixels);
     void pm_free(void* ctx);
   }
   ```
2. Compile to `.so` / `.dylib` for each platform.
3. Create `DartFfiBlemishEngine` implementing `BlemishRemovalEngine` using
   `dart:ffi` to call the C functions directly.
4. Swap into `BlemishEngineFactory.create()` — zero changes to UI or Cubit.

### 8c. GPU acceleration

For real-time brush preview:
- Use `flutter_shaders` or a `FragmentShader` to run the mask compositing
  on the GPU.
- Keep the patch search on CPU (it's not parallelisable without GPGPU).
- Use compute shaders via `dart:ffi` + Metal/Vulkan for the blend pass.

### 8d. ML-based blemish detection

Add an `AutoDetectBlemishesUseCase` that:
1. Runs a lightweight skin segmentation model (e.g. MediaPipe Face Mesh).
2. Detects local dark/bright spots deviating from the skin tone regression.
3. Auto-generates `BlemishOperation` objects for each detected spot.
4. User reviews and accepts/rejects before final apply.


## 9. KNOWN LIMITATIONS AND IMPROVEMENT PATH
─────────────────────────────────────────────────────────────────────────────────

| Limitation | Impact | Improvement |
|---|---|---|
| Dart patch search is O(n²) over search ring pixels | Slow on large images (>4K) | Use OpenCV inpaint or PatchMatch FFI |
| No structure-aware edge protection | May accidentally heal eyelashes/lips | Add Canny edge map; downweight patches crossing strong edges |
| Colour-shift correction is mean-based only | Visible seams on high-gradient skin | Implement Poisson image blending (seamlessClone) |
| Undo triggers full replay | ~30–100ms on complex sessions | Cache last-N preview bitmaps |
| No auto-blemish detection | User must manually brush every spot | Add ML skin-tone deviation detector |
| Single quality preview (not tiled) | Recomputes full image on undo | Process only dirty tiles (tile-based dirty tracking) |
| No project save UI | Operations lost on app close | Wire FileBlemishSessionRepository to an auto-save timer |
| `EngineIsolateWorker` spawns one isolate | Cannot parallelise multiple ops | Spawn a pool of N workers; distribute ops across them |


## 10. EXTENDING TO OTHER SKIN RETOUCH TOOLS
─────────────────────────────────────────────────────────────────────────────────

The architecture is designed for extension. To add Wrinkle Reducer:

1. Create `WrinkleOperation` extending from the same `RetouchOperation` base.
2. Implement `WrinkleRemovalEngine` (or add a mode to `DartBlemishEngine`).
3. Add `WrinkleCubit` or extend `BlemishCubit` with a tool-mode enum.
4. Reuse `MaskGenerationService`, `HistoryService`, `ExportService` unchanged.
5. Reuse `BlemishEditCanvas` — it is tool-agnostic.

All domain entities (`MaskData`, `BrushSettings`, `BlemishOperation`)
are already extensible via `copyWith` and JSON serialization.
