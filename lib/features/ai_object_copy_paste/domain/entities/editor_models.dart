import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;

enum ActiveDocumentRole { source, target }

enum CanvasInteractionMode {
  selectRectangle,
  selectLasso,
  smartTap,
  smartPersonTap,
  transform,
}

enum SelectionTool { rectangle, lasso, smart }

enum SelectionHandle { topLeft, topRight, bottomLeft, bottomRight }

class EditorDocument {
  const EditorDocument({
    required this.id,
    required this.name,
    required this.bytes,
    required this.bitmap,
    required this.preview,
  });

  final String id;
  final String name;
  final Uint8List bytes;
  final img.Image bitmap;
  final ui.Image preview;

  int get width => bitmap.width;
  int get height => bitmap.height;
}

class SelectionMaskData {
  const SelectionMaskData({
    required this.bounds,
    required this.width,
    required this.height,
    required this.alpha,
  });

  final ui.Rect bounds;
  final int width;
  final int height;
  final List<int> alpha;
}

class SelectionRegion {
  const SelectionRegion({
    required this.documentId,
    required this.tool,
    required this.bounds,
    this.path = const <ui.Offset>[],
    this.feather = 12,
    this.expand = 0,
    this.maskData,
  });

  final String documentId;
  final SelectionTool tool;
  final ui.Rect bounds;
  final List<ui.Offset> path;
  final double feather;
  final double expand;
  final SelectionMaskData? maskData;

  SelectionRegion copyWith({
    String? documentId,
    SelectionTool? tool,
    ui.Rect? bounds,
    List<ui.Offset>? path,
    double? feather,
    double? expand,
    SelectionMaskData? maskData,
    bool clearMaskData = false,
  }) {
    return SelectionRegion(
      documentId: documentId ?? this.documentId,
      tool: tool ?? this.tool,
      bounds: bounds ?? this.bounds,
      path: path ?? this.path,
      feather: feather ?? this.feather,
      expand: expand ?? this.expand,
      maskData: clearMaskData ? null : (maskData ?? this.maskData),
    );
  }
}

class PatchClipboard {
  const PatchClipboard({
    required this.id,
    required this.sourceDocumentId,
    required this.pngBytes,
    required this.bitmap,
    required this.preview,
    required this.sourceBounds,
  });

  final String id;
  final String sourceDocumentId;
  final Uint8List pngBytes;
  final img.Image bitmap;
  final ui.Image preview;
  final ui.Rect sourceBounds;

  int get width => bitmap.width;
  int get height => bitmap.height;
}

class PastedItem {
  const PastedItem({
    required this.id,
    required this.clipboard,
    required this.targetDocumentId,
    required this.center,
    this.scale = 1,
    this.rotation = 0,
    this.flipX = false,
    this.flipY = false,
    this.opacity = 1,
    this.feather = 10,
    this.colorMatchStrength = 0.25,
    this.lightingMatchStrength = 0.25,
    this.visible = true,
  });

  final String id;
  final PatchClipboard clipboard;
  final String targetDocumentId;
  final ui.Offset center;
  final double scale;
  final double rotation;
  final bool flipX;
  final bool flipY;
  final double opacity;
  final double feather;
  final double colorMatchStrength;
  final double lightingMatchStrength;
  final bool visible;

  ui.Size get baseSize => ui.Size(
        clipboard.width.toDouble(),
        clipboard.height.toDouble(),
      );

  PastedItem copyWith({
    String? id,
    PatchClipboard? clipboard,
    String? targetDocumentId,
    ui.Offset? center,
    double? scale,
    double? rotation,
    bool? flipX,
    bool? flipY,
    double? opacity,
    double? feather,
    double? colorMatchStrength,
    double? lightingMatchStrength,
    bool? visible,
  }) {
    return PastedItem(
      id: id ?? this.id,
      clipboard: clipboard ?? this.clipboard,
      targetDocumentId: targetDocumentId ?? this.targetDocumentId,
      center: center ?? this.center,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      flipX: flipX ?? this.flipX,
      flipY: flipY ?? this.flipY,
      opacity: opacity ?? this.opacity,
      feather: feather ?? this.feather,
      colorMatchStrength: colorMatchStrength ?? this.colorMatchStrength,
      lightingMatchStrength:
          lightingMatchStrength ?? this.lightingMatchStrength,
      visible: visible ?? this.visible,
    );
  }
}

class EditorSessionState {
  const EditorSessionState({
    this.sourceDocument,
    this.targetDocument,
    this.activeRole = ActiveDocumentRole.source,
    this.interactionMode = CanvasInteractionMode.selectRectangle,
    this.selection,
    this.clipboard,
    this.pendingItem,
    this.items = const <PastedItem>[],
    this.selectedItemId,
    this.showLayers = false,
    this.isBusy = false,
    this.isExporting = false,
    this.canUndo = false,
    this.canRedo = false,
    this.statusMessage,
  });

  final EditorDocument? sourceDocument;
  final EditorDocument? targetDocument;
  final ActiveDocumentRole activeRole;
  final CanvasInteractionMode interactionMode;
  final SelectionRegion? selection;
  final PatchClipboard? clipboard;
  final PastedItem? pendingItem;
  final List<PastedItem> items;
  final String? selectedItemId;
  final bool showLayers;
  final bool isBusy;
  final bool isExporting;
  final bool canUndo;
  final bool canRedo;
  final String? statusMessage;

  EditorDocument? get activeDocument =>
      activeRole == ActiveDocumentRole.source ? sourceDocument : targetDocument;

  EditorDocument? get effectiveTargetDocument =>
      targetDocument ?? sourceDocument;

  bool get hasDualDocument =>
      sourceDocument != null &&
      targetDocument != null &&
      sourceDocument!.id != targetDocument!.id;

  EditorSessionState copyWith({
    EditorDocument? sourceDocument,
    EditorDocument? targetDocument,
    ActiveDocumentRole? activeRole,
    CanvasInteractionMode? interactionMode,
    SelectionRegion? selection,
    bool clearSelection = false,
    PatchClipboard? clipboard,
    bool clearClipboard = false,
    PastedItem? pendingItem,
    bool clearPendingItem = false,
    List<PastedItem>? items,
    String? selectedItemId,
    bool clearSelectedItem = false,
    bool? showLayers,
    bool? isBusy,
    bool? isExporting,
    bool? canUndo,
    bool? canRedo,
    String? statusMessage,
    bool clearStatus = false,
  }) {
    return EditorSessionState(
      sourceDocument: sourceDocument ?? this.sourceDocument,
      targetDocument: targetDocument ?? this.targetDocument,
      activeRole: activeRole ?? this.activeRole,
      interactionMode: interactionMode ?? this.interactionMode,
      selection: clearSelection ? null : (selection ?? this.selection),
      clipboard: clearClipboard ? null : (clipboard ?? this.clipboard),
      pendingItem: clearPendingItem ? null : (pendingItem ?? this.pendingItem),
      items: items ?? this.items,
      selectedItemId:
          clearSelectedItem ? null : (selectedItemId ?? this.selectedItemId),
      showLayers: showLayers ?? this.showLayers,
      isBusy: isBusy ?? this.isBusy,
      isExporting: isExporting ?? this.isExporting,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}

class HistorySnapshot {
  const HistorySnapshot({
    required this.items,
    required this.selection,
    required this.clipboard,
    required this.pendingItem,
    required this.selectedItemId,
  });

  final List<PastedItem> items;
  final SelectionRegion? selection;
  final PatchClipboard? clipboard;
  final PastedItem? pendingItem;
  final String? selectedItemId;
}
