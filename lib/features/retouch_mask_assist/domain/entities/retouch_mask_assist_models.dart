import 'dart:typed_data';

enum MaskEditMode { add, erase }

enum MaskCreationMode { manual, aiAssist }

enum MaskTransformAction { expand, contract, clear }

enum RetouchToolType { heal, repair, expand }

enum MaskSuggestionSource { mlKitSubjectSegmentation, fallbackHeuristic }

class MaskFeatherParams {
  final double softness;

  const MaskFeatherParams({this.softness = 0});
}

class MaskSuggestionRequest {
  final Uint8List imageBytes;
  final RetouchToolType toolType;

  const MaskSuggestionRequest({
    required this.imageBytes,
    required this.toolType,
  });
}

class MaskSuggestionResult {
  final Uint8List alphaMask;
  final int width;
  final int height;
  final MaskSuggestionSource source;

  const MaskSuggestionResult({
    required this.alphaMask,
    required this.width,
    required this.height,
    required this.source,
  });
}

class EditableMaskPayload {
  final Uint8List alphaMask;
  final int width;
  final int height;
  final Uint8List previewPng;

  const EditableMaskPayload({
    required this.alphaMask,
    required this.width,
    required this.height,
    required this.previewPng,
  });
}
