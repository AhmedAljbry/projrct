import '../models/af_blur_settings.dart';
import '../models/af_mask_data.dart';

/// Contract for mask post-processing / refinement engines.
abstract interface class AfMaskRefiner {
  AfMaskData refine({
    required AfMaskData mask,
    required AfBlurSettings settings,
    required List<dynamic> manualStrokes,
  });
}
