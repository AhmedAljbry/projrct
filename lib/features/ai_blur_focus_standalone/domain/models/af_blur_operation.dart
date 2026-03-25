import 'package:equatable/equatable.dart';
import 'af_blur_settings.dart';
import 'af_mask_data.dart';

/// Complete snapshot of one editing operation (settings + mask + strokes).
class AfBlurOperation extends Equatable {
  const AfBlurOperation({
    required this.settings,
    this.maskData,
    this.manualStrokes = const [],
  });

  factory AfBlurOperation.initial() => const AfBlurOperation(
        settings: AfBlurSettings(),
      );

  final AfBlurSettings settings;
  final AfMaskData? maskData;
  final List<AfManualStroke> manualStrokes;

  AfBlurOperation copyWith({
    AfBlurSettings? settings,
    AfMaskData? maskData,
    List<AfManualStroke>? manualStrokes,
    bool clearMask = false,
  }) =>
      AfBlurOperation(
        settings: settings ?? this.settings,
        maskData: clearMask ? null : (maskData ?? this.maskData),
        manualStrokes: manualStrokes ?? this.manualStrokes,
      );

  @override
  List<Object?> get props => [settings, maskData, manualStrokes];
}
