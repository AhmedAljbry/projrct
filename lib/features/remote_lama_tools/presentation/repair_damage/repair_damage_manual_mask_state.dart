part of 'repair_damage_manual_mask_cubit.dart';

class RepairDamageManualMaskState extends Equatable {
  static const Object _maskPreviewUnchanged = Object();

  const RepairDamageManualMaskState({
    this.sourceImageBytes,
    this.maskAlpha,
    this.maskPreviewPng,
    this.imageWidth = 0,
    this.imageHeight = 0,
    this.editMode = MaskEditMode.add,
    this.feather = 3,
    this.expansionLevel = 0,
    this.previewVisible = true,
    this.canUndo = false,
    this.canRedo = false,
    this.hasMaskContent = false,
  });

  final Uint8List? sourceImageBytes;
  final Uint8List? maskAlpha;
  final Uint8List? maskPreviewPng;
  final int imageWidth;
  final int imageHeight;
  final MaskEditMode editMode;
  final double feather;
  final int expansionLevel;
  final bool previewVisible;
  final bool canUndo;
  final bool canRedo;
  final bool hasMaskContent;

  bool get isReady =>
      sourceImageBytes != null && imageWidth > 0 && imageHeight > 0;

  RepairDamageManualMaskState copyWith({
    Uint8List? sourceImageBytes,
    Uint8List? maskAlpha,
    Object? maskPreviewPng = _maskPreviewUnchanged,
    int? imageWidth,
    int? imageHeight,
    MaskEditMode? editMode,
    double? feather,
    int? expansionLevel,
    bool? previewVisible,
    bool? canUndo,
    bool? canRedo,
    bool? hasMaskContent,
  }) {
    return RepairDamageManualMaskState(
      sourceImageBytes: sourceImageBytes ?? this.sourceImageBytes,
      maskAlpha: maskAlpha ?? this.maskAlpha,
      maskPreviewPng: identical(maskPreviewPng, _maskPreviewUnchanged)
          ? this.maskPreviewPng
          : maskPreviewPng as Uint8List?,
      imageWidth: imageWidth ?? this.imageWidth,
      imageHeight: imageHeight ?? this.imageHeight,
      editMode: editMode ?? this.editMode,
      feather: feather ?? this.feather,
      expansionLevel: expansionLevel ?? this.expansionLevel,
      previewVisible: previewVisible ?? this.previewVisible,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      hasMaskContent: hasMaskContent ?? this.hasMaskContent,
    );
  }

  @override
  List<Object?> get props => [
        sourceImageBytes,
        maskAlpha,
        maskPreviewPng,
        imageWidth,
        imageHeight,
        editMode,
        feather,
        expansionLevel,
        previewVisible,
        canUndo,
        canRedo,
        hasMaskContent,
      ];
}
