import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

Future<ui.Image> decodeUiImage(Uint8List bytes) {
  final completer = Completer<ui.Image>();
  ui.decodeImageFromList(bytes, completer.complete);
  return completer.future;
}
