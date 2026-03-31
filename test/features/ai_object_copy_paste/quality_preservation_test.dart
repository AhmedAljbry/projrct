import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:untitled2/features/ai_object_copy_paste/domain/entities/editor_models.dart';
import 'package:untitled2/features/ai_object_copy_paste/engine/object_copy_paste_engine.dart';
import 'package:untitled2/features/ai_object_copy_paste/services/export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('paste keeps original scale when the patch fits the target', () async {
    final preview = await _buildPreviewImage();
    final sourceBitmap = img.Image(width: 320, height: 240, numChannels: 4);
    final targetBitmap = img.Image(width: 1000, height: 1000, numChannels: 4);
    final clipboard = PatchClipboard(
      id: 'clip',
      sourceDocumentId: 'source',
      pngBytes: Uint8List(0),
      bitmap: sourceBitmap,
      preview: preview,
      sourceBounds: const ui.Rect.fromLTWH(0, 0, 320, 240),
    );
    final document = EditorDocument(
      id: 'target',
      name: 'target',
      bytes: Uint8List(0),
      bitmap: targetBitmap,
      preview: preview,
    );

    final engine = ObjectCopyPasteEngine();
    final item = engine.paste(
      clipboard: clipboard,
      targetDocument: document,
    );

    expect(item.scale, 1.0);
    expect(item.feather, 0.0);
    final rect = engine.transformedRect(item);
    expect(rect.left, greaterThanOrEqualTo(0));
    expect(rect.top, greaterThanOrEqualTo(0));
    expect(rect.right, lessThanOrEqualTo(document.width.toDouble()));
    expect(rect.bottom, lessThanOrEqualTo(document.height.toDouble()));
  });

  test(
      'export preserves patch pixels when no quality-reducing effects are used',
      () async {
    final preview = await _buildPreviewImage();
    final targetBitmap = img.Image(width: 4, height: 4, numChannels: 4);
    final patchBitmap = img.Image(width: 2, height: 2, numChannels: 4)
      ..setPixelRgba(0, 0, 255, 0, 0, 255)
      ..setPixelRgba(1, 0, 0, 255, 0, 255)
      ..setPixelRgba(0, 1, 0, 0, 255, 255)
      ..setPixelRgba(1, 1, 255, 255, 255, 255);
    final clipboard = PatchClipboard(
      id: 'clip',
      sourceDocumentId: 'source',
      pngBytes: Uint8List(0),
      bitmap: patchBitmap,
      preview: preview,
      sourceBounds: const ui.Rect.fromLTWH(0, 0, 2, 2),
    );
    final document = EditorDocument(
      id: 'target',
      name: 'target',
      bytes: Uint8List(0),
      bitmap: targetBitmap,
      preview: preview,
    );
    final item = PastedItem(
      id: 'item',
      clipboard: clipboard,
      targetDocumentId: document.id,
      center: const ui.Offset(1, 1),
      scale: 1,
      feather: 0,
      colorMatchStrength: 0,
      lightingMatchStrength: 0,
    );

    final exportedBytes = ExportService().export(
      targetDocument: document,
      items: [item],
      asPng: true,
    );
    final exported = img.decodeImage(exportedBytes);

    expect(exported, isNotNull);
    expect(exported!.getPixel(0, 0).r, 255);
    expect(exported.getPixel(0, 0).g, 0);
    expect(exported.getPixel(0, 0).b, 0);
    expect(exported.getPixel(1, 0).r, 0);
    expect(exported.getPixel(1, 0).g, 255);
    expect(exported.getPixel(1, 0).b, 0);
    expect(exported.getPixel(0, 1).r, 0);
    expect(exported.getPixel(0, 1).g, 0);
    expect(exported.getPixel(0, 1).b, 255);
    expect(exported.getPixel(1, 1).r, 255);
    expect(exported.getPixel(1, 1).g, 255);
    expect(exported.getPixel(1, 1).b, 255);
  });
}

Future<ui.Image> _buildPreviewImage() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, 2, 2),
    Paint()..color = Colors.white,
  );
  final picture = recorder.endRecording();
  return picture.toImage(2, 2);
}
