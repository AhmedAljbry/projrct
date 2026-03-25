import 'package:untitled2/features/blur_focus/domain/models/blur_focus_operation.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class BlurFocusOperationMapper {
  const BlurFocusOperationMapper();

  BlurFocusOperation updateSettings(BlurFocusOperation operation, BlurSettings settings) {
    return operation.copyWith(settings: settings);
  }

  BlurFocusOperation attachSegmentation(BlurFocusOperation operation, SegmentationResultData segmentation) {
    return operation.copyWith(segmentation: segmentation);
  }

  BlurFocusOperation appendStroke(BlurFocusOperation operation, ManualMaskStroke stroke) {
    final updated = List<ManualMaskStroke>.from(operation.manualStrokes)..add(stroke);
    return operation.copyWith(manualStrokes: updated);
  }

  BlurFocusOperation clearManualRefinements(BlurFocusOperation operation) {
    return operation.copyWith(manualStrokes: const []);
  }
}
