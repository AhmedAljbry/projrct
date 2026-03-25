import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

import '../domain/entities/editor_models.dart';
import '../utils/id_generator.dart';

class ImageCodecService {
  Future<EditorDocument> decodeDocument({
    required Uint8List bytes,
    required String name,
  }) async {
    final bitmap = img.decodeImage(bytes);
    if (bitmap == null) {
      throw StateError('Unable to decode image');
    }

    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return EditorDocument(
      id: IdGenerator.next('doc_'),
      name: name,
      bytes: Uint8List.fromList(bytes),
      bitmap: bitmap,
      preview: frame.image,
    );
  }

  Future<PatchClipboard> decodeClipboard({
    required Uint8List pngBytes,
    required String sourceDocumentId,
    required ui.Rect sourceBounds,
  }) async {
    final bitmap = img.decodeImage(pngBytes);
    if (bitmap == null) {
      throw StateError('Unable to decode clipboard patch');
    }
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    return PatchClipboard(
      id: IdGenerator.next('clip_'),
      sourceDocumentId: sourceDocumentId,
      pngBytes: Uint8List.fromList(pngBytes),
      bitmap: bitmap,
      preview: frame.image,
      sourceBounds: sourceBounds,
    );
  }
}
