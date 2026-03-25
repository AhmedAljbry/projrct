import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

abstract class FocusMaskRefinementEngine {
  SegmentationResultData refine({
    required SegmentationResultData segmentation,
    required BlurSettings settings,
    required List<ManualMaskStroke> manualStrokes,
  });
}
