import 'dart:math' as math;
import 'dart:ui';

import '../domain/entities/editor_models.dart';
import '../utils/id_generator.dart';

class ObjectCopyPasteEngine {
  PastedItem paste({
    required PatchClipboard clipboard,
    required EditorDocument targetDocument,
    SelectionRegion? sourceSelection,
    List<PastedItem> existingItems = const <PastedItem>[],
  }) {
    final defaultCenter = sourceSelection != null &&
            sourceSelection.documentId == targetDocument.id
        ? Offset(
            (sourceSelection.bounds.center.dx + 36)
                .clamp(0.0, targetDocument.width.toDouble()),
            (sourceSelection.bounds.center.dy + 36)
                .clamp(0.0, targetDocument.height.toDouble()),
          )
        : Offset(
            targetDocument.width / 2,
            targetDocument.height / 2,
          );

    return PastedItem(
      id: IdGenerator.next('item_'),
      clipboard: clipboard,
      targetDocumentId: targetDocument.id,
      center: defaultCenter,
      scale: _initialScale(clipboard, targetDocument),
      colorMatchStrength: 0.28,
      lightingMatchStrength: 0.28,
      feather: 10,
      opacity: 1,
    );
  }

  PastedItem duplicate(PastedItem item, Size targetSize) {
    return item.copyWith(
      id: IdGenerator.next('item_'),
      center: Offset(
        (item.center.dx + 28).clamp(0.0, targetSize.width),
        (item.center.dy + 28).clamp(0.0, targetSize.height),
      ),
    );
  }

  List<PastedItem> moveUp(List<PastedItem> items, String itemId) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index < 0 || index == items.length - 1) {
      return items;
    }
    final mutable = List<PastedItem>.from(items);
    final item = mutable.removeAt(index);
    mutable.insert(index + 1, item);
    return mutable;
  }

  List<PastedItem> moveDown(List<PastedItem> items, String itemId) {
    final index = items.indexWhere((item) => item.id == itemId);
    if (index <= 0) {
      return items;
    }
    final mutable = List<PastedItem>.from(items);
    final item = mutable.removeAt(index);
    mutable.insert(index - 1, item);
    return mutable;
  }

  Rect transformedRect(PastedItem item) {
    final size = Size(
      item.baseSize.width * item.scale,
      item.baseSize.height * item.scale,
    );
    return Rect.fromCenter(
      center: item.center,
      width: size.width,
      height: size.height,
    );
  }

  double _initialScale(
      PatchClipboard clipboard, EditorDocument targetDocument) {
    final maxDimension = math.max(clipboard.width, clipboard.height).toDouble();
    final targetMax =
        math.max(targetDocument.width, targetDocument.height).toDouble();
    if (maxDimension == 0) {
      return 1;
    }
    final scale = math.min(1.0, targetMax * 0.45 / maxDimension);
    return scale.clamp(0.2, 2.5);
  }
}
