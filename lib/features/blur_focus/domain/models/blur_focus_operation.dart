import 'package:equatable/equatable.dart';
import 'package:untitled2/features/blur_focus/domain/models/blur_settings.dart';
import 'package:untitled2/features/blur_focus/domain/models/smart_mask_models.dart';

class BlurFocusOperation extends Equatable {
  final String id;
  final BlurSettings settings;
  final SegmentationResultData? segmentation;
  final List<ManualMaskStroke> manualStrokes;
  final DateTime updatedAt;

  const BlurFocusOperation({
    required this.id,
    required this.settings,
    required this.segmentation,
    required this.manualStrokes,
    required this.updatedAt,
  });

  factory BlurFocusOperation.initial() => BlurFocusOperation(
        id: 'blur-focus-initial',
        settings: const BlurSettings(),
        segmentation: null,
        manualStrokes: const [],
        updatedAt: DateTime.now(),
      );

  BlurFocusOperation copyWith({
    String? id,
    BlurSettings? settings,
    SegmentationResultData? segmentation,
    bool clearSegmentation = false,
    List<ManualMaskStroke>? manualStrokes,
    DateTime? updatedAt,
  }) {
    return BlurFocusOperation(
      id: id ?? this.id,
      settings: settings ?? this.settings,
      segmentation: clearSegmentation ? null : (segmentation ?? this.segmentation),
      manualStrokes: manualStrokes ?? this.manualStrokes,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'settings': settings.toJson(),
        'segmentation': segmentation?.toJson(),
        'manualStrokes': manualStrokes.map((stroke) => stroke.toJson()).toList(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BlurFocusOperation.fromJson(Map<String, dynamic> json) {
    return BlurFocusOperation(
      id: json['id'] as String? ?? 'blur-focus-restored',
      settings: BlurSettings.fromJson(Map<String, dynamic>.from(json['settings'] as Map? ?? const {})),
      segmentation: json['segmentation'] == null
          ? null
          : SegmentationResultData.fromJson(Map<String, dynamic>.from(json['segmentation'] as Map)),
      manualStrokes: ((json['manualStrokes'] as List?) ?? const [])
          .map((stroke) => ManualMaskStroke.fromJson(Map<String, dynamic>.from(stroke as Map)))
          .toList(),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, settings, segmentation, manualStrokes, updatedAt];
}
