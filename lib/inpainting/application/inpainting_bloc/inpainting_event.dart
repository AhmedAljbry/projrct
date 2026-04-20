import 'dart:typed_data';

sealed class InpaintingEvent {}

class InpaintingPrepare extends InpaintingEvent {
  final String? message;
  InpaintingPrepare({this.message});
}

class InpaintingStart extends InpaintingEvent {
  final Uint8List imageBytes;
  final Uint8List maskBytes;
  InpaintingStart({required this.imageBytes, required this.maskBytes});
}

class InpaintingPreparationFailed extends InpaintingEvent {
  final String message;
  InpaintingPreparationFailed(this.message);
}

class InpaintingCancel extends InpaintingEvent {}
class InpaintingReset extends InpaintingEvent {}
