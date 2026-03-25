import 'dart:typed_data';

sealed class InpaintingEvent {}

class InpaintingStart extends InpaintingEvent {
  final Uint8List imageBytes;
  final Uint8List maskBytes;
  InpaintingStart({required this.imageBytes, required this.maskBytes});
}

class InpaintingCancel extends InpaintingEvent {}
class InpaintingReset extends InpaintingEvent {}