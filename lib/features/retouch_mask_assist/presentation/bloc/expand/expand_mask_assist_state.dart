part of 'expand_mask_assist_cubit.dart';

enum MaskGenerationStatus { idle, generating, ready, failure }

class ExpandMaskAssistState extends Equatable {
  final MaskCreationMode creationMode;
  final MaskEditMode editMode;
  final Uint8List? sourceImageBytes;
  final Uint8List? maskAlpha;
  final Uint8List? maskPreviewPng;
  final int maskWidth;
  final int maskHeight;
  final double feather;
  final int expansionLevel;
  final bool previewVisible;
  final bool canUndo;
  final bool canRedo;
  final MaskGenerationStatus generationStatus;
  final String? errorMessage;
  final MaskSuggestionSource? source;

  const ExpandMaskAssistState({
    this.creationMode = MaskCreationMode.manual,
    this.editMode = MaskEditMode.add,
    this.sourceImageBytes,
    this.maskAlpha,
    this.maskPreviewPng,
    this.maskWidth = 0,
    this.maskHeight = 0,
    this.feather = 2,
    this.expansionLevel = 0,
    this.previewVisible = true,
    this.canUndo = false,
    this.canRedo = false,
    this.generationStatus = MaskGenerationStatus.idle,
    this.errorMessage,
    this.source,
  });

  bool get hasSuggestion =>
      maskAlpha != null && maskWidth > 0 && maskHeight > 0;

  ExpandMaskAssistState copyWith({
    MaskCreationMode? creationMode,
    MaskEditMode? editMode,
    Uint8List? sourceImageBytes,
    Uint8List? maskAlpha,
    Uint8List? maskPreviewPng,
    int? maskWidth,
    int? maskHeight,
    double? feather,
    int? expansionLevel,
    bool? previewVisible,
    bool? canUndo,
    bool? canRedo,
    MaskGenerationStatus? generationStatus,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool clearMaskData = false,
    MaskSuggestionSource? source,
  }) {
    return ExpandMaskAssistState(
      creationMode: creationMode ?? this.creationMode,
      editMode: editMode ?? this.editMode,
      sourceImageBytes: sourceImageBytes ?? this.sourceImageBytes,
      maskAlpha: clearMaskData ? null : (maskAlpha ?? this.maskAlpha),
      maskPreviewPng:
          clearMaskData ? null : (maskPreviewPng ?? this.maskPreviewPng),
      maskWidth: clearMaskData ? 0 : (maskWidth ?? this.maskWidth),
      maskHeight: clearMaskData ? 0 : (maskHeight ?? this.maskHeight),
      feather: feather ?? this.feather,
      expansionLevel: expansionLevel ?? this.expansionLevel,
      previewVisible: previewVisible ?? this.previewVisible,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      generationStatus: generationStatus ?? this.generationStatus,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      source: clearMaskData ? null : (source ?? this.source),
    );
  }

  @override
  List<Object?> get props => [
        creationMode,
        editMode,
        sourceImageBytes,
        maskAlpha,
        maskPreviewPng,
        maskWidth,
        maskHeight,
        feather,
        expansionLevel,
        previewVisible,
        canUndo,
        canRedo,
        generationStatus,
        errorMessage,
        source,
      ];
}
