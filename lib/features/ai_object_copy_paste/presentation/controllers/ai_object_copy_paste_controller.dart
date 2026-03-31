import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';

import '../../domain/entities/editor_models.dart';
import '../../engine/object_copy_paste_engine.dart';
import '../../services/export_service.dart';
import '../../services/history_manager.dart';
import '../../services/image_codec_service.dart';
import '../../services/segmentation_adapter.dart';
import '../../services/selection_service.dart';

class AiObjectCopyPasteController extends ChangeNotifier {
  AiObjectCopyPasteController({
    ImagePicker? picker,
    ImageCodecService? codecService,
    SelectionService? selectionService,
    SegmentationAdapter? segmentationAdapter,
    ExportService? exportService,
    ObjectCopyPasteEngine? engine,
    HistoryManager? history,
  })  : _picker = picker ?? ImagePicker(),
        _codecService = codecService ?? ImageCodecService(),
        _selectionService = selectionService ?? SelectionService(),
        _segmentationAdapter =
            segmentationAdapter ?? HybridSegmentationAdapter(),
        _exportService = exportService ?? ExportService(),
        _engine = engine ?? ObjectCopyPasteEngine(),
        _history = history ?? HistoryManager() {
    _history.reset(_snapshot(_state));
    _syncHistoryFlags();
  }

  final ImagePicker _picker;
  final ImageCodecService _codecService;
  final SelectionService _selectionService;
  final SegmentationAdapter _segmentationAdapter;
  final ExportService _exportService;
  final ObjectCopyPasteEngine _engine;
  final HistoryManager _history;

  EditorSessionState _state = const EditorSessionState();
  Offset? _selectionStart;
  List<Offset> _lassoPoints = <Offset>[];

  EditorSessionState get state => _state;
  bool get canPaste => _state.clipboard != null;
  bool get canConfirm => _state.pendingItem != null || _state.selection != null;

  Future<void> importSourceImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    _setBusy(true, 'Loading source image...');
    try {
      final document = await _codecService.decodeDocument(
        bytes: await file.readAsBytes(),
        name: file.name,
      );
      _state = EditorSessionState(
        sourceDocument: document,
        targetDocument: document,
        activeRole: ActiveDocumentRole.source,
        interactionMode: _state.interactionMode,
        canUndo: false,
        canRedo: false,
      );
      _history.reset(_snapshot(_state));
      _syncHistoryFlags();
      _setStatus(
          'Source image ready. Draw a region, tap Smart, or use People for fast person selection.');
    } catch (_) {
      _setStatus('Unable to load that image.');
    } finally {
      _setBusy(false, null);
    }
  }

  Future<void> importTargetImage() async {
    if (_state.sourceDocument == null) {
      await importSourceImage();
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    _setBusy(true, 'Loading target image...');
    try {
      final document = await _codecService.decodeDocument(
        bytes: await file.readAsBytes(),
        name: file.name,
      );
      _state = _state.copyWith(
        targetDocument: document,
        activeRole: ActiveDocumentRole.source,
        clearSelectedItem: true,
        clearSelection: true,
        clearPendingItem: true,
      );
      _history.reset(_snapshot(_state));
      _syncHistoryFlags();
      _setStatus(
          'Target image ready. Select on source, copy, then paste into target.');
    } catch (_) {
      _setStatus('Unable to load the target image.');
    } finally {
      _setBusy(false, null);
    }
  }

  void setActiveRole(ActiveDocumentRole role) {
    if (role == ActiveDocumentRole.target &&
        _state.effectiveTargetDocument == null) {
      return;
    }
    _state = _state.copyWith(activeRole: role, clearSelectedItem: false);
    notifyListeners();
  }

  void setInteractionMode(CanvasInteractionMode mode) {
    _state = _state.copyWith(
      interactionMode: mode,
      clearSelectedItem: mode != CanvasInteractionMode.transform,
    );
    if (mode == CanvasInteractionMode.smartTap) {
      _setStatus('Smart mode enabled. Tap the object you want to select.');
      return;
    }
    if (mode == CanvasInteractionMode.smartPersonTap) {
      _setStatus(
          'People mode enabled. Tap the person for faster high-accuracy selection.');
      return;
    }
    notifyListeners();
  }

  void enterSmartSelectionMode() {
    setInteractionMode(CanvasInteractionMode.smartTap);
  }

  void enterPeopleSelectionMode() {
    setInteractionMode(CanvasInteractionMode.smartPersonTap);
  }

  void toggleLayers() {
    _state = _state.copyWith(showLayers: !_state.showLayers);
    notifyListeners();
  }

  void beginSelection(Offset imagePoint) {
    final document = _state.activeDocument;
    if (document == null) {
      return;
    }
    if (_state.interactionMode == CanvasInteractionMode.selectRectangle) {
      _selectionStart = imagePoint;
      _state = _state.copyWith(
        selection: SelectionRegion(
          documentId: document.id,
          tool: SelectionTool.rectangle,
          bounds: Rect.fromPoints(imagePoint, imagePoint),
          feather: _state.selection?.feather ?? 12,
          expand: _state.selection?.expand ?? 0,
        ),
        clearSelectedItem: true,
      );
      notifyListeners();
    } else if (_state.interactionMode == CanvasInteractionMode.selectLasso) {
      _lassoPoints = <Offset>[imagePoint];
      _state = _state.copyWith(
        selection: SelectionRegion(
          documentId: document.id,
          tool: SelectionTool.lasso,
          bounds: Rect.fromPoints(imagePoint, imagePoint),
          path: _lassoPoints,
          feather: _state.selection?.feather ?? 12,
          expand: _state.selection?.expand ?? 0,
        ),
        clearSelectedItem: true,
      );
      notifyListeners();
    }
  }

  void updateSelection(Offset imagePoint) {
    final selection = _state.selection;
    if (selection == null) {
      return;
    }
    if (_state.interactionMode == CanvasInteractionMode.selectRectangle &&
        _selectionStart != null) {
      replaceSelection(
        selection.copyWith(
          bounds: Rect.fromPoints(_selectionStart!, imagePoint),
          clearMaskData: true,
        ),
      );
    } else if (_state.interactionMode == CanvasInteractionMode.selectLasso) {
      _lassoPoints = List<Offset>.from(_lassoPoints)..add(imagePoint);
      replaceSelection(
        selection.copyWith(
          path: _lassoPoints,
          bounds: _boundsFromPoints(_lassoPoints),
          clearMaskData: true,
        ),
      );
    }
  }

  void endSelection() {
    final selection = _state.selection;
    _selectionStart = null;
    _lassoPoints = <Offset>[];
    if (selection == null) {
      return;
    }
    final width = selection.bounds.width.abs();
    final height = selection.bounds.height.abs();
    final lassoTooSmall =
        selection.tool == SelectionTool.lasso && selection.path.length < 3;
    if (width < 6 || height < 6 || lassoTooSmall) {
      _state = _state.copyWith(clearSelection: true);
      notifyListeners();
      _setStatus('Make a larger selection, then press Confirm or Copy.');
      return;
    }
    _commitHistory();
    _setStatus(
        'Selection ready. Move it, resize it, then press Confirm or Copy.');
  }

  Future<void> runSmartSelectionAtPoint(Offset imagePoint) async {
    final document = _state.activeDocument;
    if (document == null) {
      _setStatus('Import an image first.');
      return;
    }
    _setBusy(true, 'Detecting object...');
    try {
      final selection = await _segmentationAdapter.buildSmartSelection(
        document,
        focusPoint: imagePoint,
      );
      _state = _state.copyWith(
        selection: selection,
        clearSelectedItem: true,
        interactionMode: CanvasInteractionMode.selectRectangle,
      );
      _commitHistory();
      _setStatus('Object selected. Adjust it, then press Confirm or Copy.');
    } catch (_) {
      _state = _state.copyWith(
          interactionMode: CanvasInteractionMode.selectRectangle);
      _setStatus('Smart selection failed. Tap again or use manual selection.');
    } finally {
      _setBusy(false, null);
    }
  }

  Future<void> runPeopleSelectionAtPoint(Offset imagePoint) async {
    final document = _state.activeDocument;
    if (document == null) {
      _setStatus('Import an image first.');
      return;
    }
    _setBusy(true, 'Detecting person...');
    try {
      final selection = await _segmentationAdapter.buildPersonSelection(
        document,
        focusPoint: imagePoint,
      );
      _state = _state.copyWith(
        selection: selection,
        clearSelectedItem: true,
        interactionMode: CanvasInteractionMode.selectRectangle,
      );
      _commitHistory();
      _setStatus('Person selected. Adjust it, then press Confirm or Copy.');
    } catch (_) {
      _state = _state.copyWith(
          interactionMode: CanvasInteractionMode.selectRectangle);
      _setStatus('People selection failed. Tap the person again or use Smart.');
    } finally {
      _setBusy(false, null);
    }
  }

  Future<void> copySelection() async {
    final document = _state.activeDocument;
    final selection = _state.selection;
    if (document == null ||
        selection == null ||
        selection.documentId != document.id) {
      _setStatus('Create a selection first.');
      return;
    }
    _setBusy(true, 'Copying selection...');
    try {
      final clipboard = await _selectionService.copySelection(
        document: document,
        selection: selection,
        codecService: _codecService,
      );
      _state = _state.copyWith(clipboard: clipboard);
      _commitHistory();
      _setStatus(
          'Copied. Press Paste to place a preview, then Confirm to apply.');
    } catch (_) {
      _setStatus('Copy failed for the current selection.');
    } finally {
      _setBusy(false, null);
    }
  }

  void pasteClipboard() {
    final clipboard = _state.clipboard;
    final target = _state.activeDocument ?? _state.effectiveTargetDocument;
    if (clipboard == null || target == null) {
      _setStatus('Copy something first, then choose a target image.');
      return;
    }
    final item = _engine.paste(
      clipboard: clipboard,
      targetDocument: target,
      sourceSelection: _state.selection,
      existingItems: _state.items,
    );
    _state = _state.copyWith(
      pendingItem: item,
      selectedItemId: item.id,
      activeRole: target.id == _state.targetDocument?.id
          ? ActiveDocumentRole.target
          : ActiveDocumentRole.source,
      interactionMode: CanvasInteractionMode.transform,
      clearSelection: true,
      showLayers: true,
    );
    notifyListeners();
    _setStatus(
        'Preview placed. Move or scale it, then press Confirm to apply.');
  }

  void confirmPendingPaste() {
    final pending = _state.pendingItem;
    if (pending == null) {
      return;
    }
    _state = _state.copyWith(
      items: List<PastedItem>.from(_state.items)..add(pending),
      clearPendingItem: true,
      selectedItemId: pending.id,
      interactionMode: CanvasInteractionMode.transform,
      showLayers: true,
    );
    _commitHistory();
    _setStatus('Paste applied to the selected image.');
  }

  void selectItem(String itemId) {
    _state = _state.copyWith(
      selectedItemId: itemId,
      interactionMode: CanvasInteractionMode.transform,
    );
    notifyListeners();
  }

  void clearSelection({bool clearSelectedItem = false}) {
    _state = _state.copyWith(
      clearSelection: true,
      clearSelectedItem: clearSelectedItem,
    );
    notifyListeners();
  }

  void deleteSelection() {
    if (_state.selection == null) {
      return;
    }
    _state = _state.copyWith(clearSelection: true);
    _commitHistory();
    _setStatus('Selection deleted.');
  }

  void replaceSelection(SelectionRegion selection, {bool commit = false}) {
    _state = _state.copyWith(selection: _normalizedSelection(selection));
    if (commit) {
      _commitHistory();
      _setStatus('Selection updated. Press Confirm or Copy when ready.');
    } else {
      notifyListeners();
    }
  }

  void translateSelectionBy(Offset delta) {
    final selection = _state.selection;
    final document = _state.activeDocument;
    if (selection == null || document == null) {
      return;
    }
    final shiftedBounds = selection.bounds.shift(delta);
    var dx = delta.dx;
    var dy = delta.dy;
    if (shiftedBounds.left < 0) {
      dx -= shiftedBounds.left;
    }
    if (shiftedBounds.top < 0) {
      dy -= shiftedBounds.top;
    }
    if (shiftedBounds.right > document.width) {
      dx -= shiftedBounds.right - document.width;
    }
    if (shiftedBounds.bottom > document.height) {
      dy -= shiftedBounds.bottom - document.height;
    }
    final corrected = Offset(dx, dy);
    final nextBounds = selection.bounds.shift(corrected);
    final nextPath = selection.path
        .map((point) => point + corrected)
        .toList(growable: false);
    replaceSelection(
      selection.copyWith(
        bounds: nextBounds,
        path: nextPath,
        maskData: _shiftedMask(selection.maskData, corrected),
      ),
    );
  }

  void resizeSelectionToPoint(Offset imagePoint) {
    final selection = _state.selection;
    final document = _state.activeDocument;
    if (selection == null || document == null) {
      return;
    }
    final topLeft = selection.bounds.topLeft;
    final clamped = _clampPointToDocument(imagePoint, document);
    final width =
        (clamped.dx - topLeft.dx).clamp(12.0, document.width - topLeft.dx);
    final height =
        (clamped.dy - topLeft.dy).clamp(12.0, document.height - topLeft.dy);
    final nextBounds = Rect.fromLTWH(topLeft.dx, topLeft.dy, width, height);

    if (selection.tool == SelectionTool.rectangle) {
      replaceSelection(
        selection.copyWith(
          bounds: nextBounds,
          clearMaskData: true,
        ),
      );
      return;
    }

    if (selection.tool == SelectionTool.lasso && selection.path.isNotEmpty) {
      final oldBounds = selection.bounds;
      final scaleX =
          oldBounds.width == 0 ? 1.0 : nextBounds.width / oldBounds.width;
      final scaleY =
          oldBounds.height == 0 ? 1.0 : nextBounds.height / oldBounds.height;
      final nextPath = selection.path.map((point) {
        final dx = point.dx - oldBounds.left;
        final dy = point.dy - oldBounds.top;
        return Offset(
            nextBounds.left + dx * scaleX, nextBounds.top + dy * scaleY);
      }).toList(growable: false);
      replaceSelection(
        selection.copyWith(
          bounds: nextBounds,
          path: nextPath,
          clearMaskData: true,
        ),
      );
    }
  }

  void commitSelectionEdit() {
    if (_state.pendingItem != null) {
      confirmPendingPaste();
      return;
    }
    if (_state.selection == null) {
      return;
    }
    _commitHistory();
    _setStatus('Selection confirmed. Press Copy when ready.');
  }

  void updateSelectionRefinement({double? feather, double? expand}) {
    final selection = _state.selection;
    if (selection == null) {
      return;
    }
    _state = _state.copyWith(
      selection: selection.copyWith(
        feather: feather,
        expand: expand,
        clearMaskData: selection.tool != SelectionTool.smart,
      ),
    );
    notifyListeners();
  }

  void updateSelectedItem({
    Offset? center,
    double? scale,
    double? rotation,
    bool? flipX,
    bool? flipY,
    double? opacity,
    double? feather,
    double? colorMatchStrength,
    double? lightingMatchStrength,
    bool? visible,
    bool commit = false,
  }) {
    final selectedId = _state.selectedItemId;
    if (selectedId == null) {
      return;
    }
    final target = _state.activeDocument ?? _state.effectiveTargetDocument;
    final pending = _state.pendingItem;
    if (pending != null && pending.id == selectedId) {
      final nextCenter = center == null || target == null
          ? (center ?? pending.center)
          : Offset(
              center.dx.clamp(0.0, target.width.toDouble()),
              center.dy.clamp(0.0, target.height.toDouble()),
            );
      _state = _state.copyWith(
        pendingItem: pending.copyWith(
          center: nextCenter,
          scale: scale?.clamp(0.1, 6.0),
          rotation: rotation,
          flipX: flipX,
          flipY: flipY,
          opacity: opacity?.clamp(0.05, 1.0),
          feather: feather?.clamp(0.0, 40.0),
          colorMatchStrength: colorMatchStrength?.clamp(0.0, 1.0),
          lightingMatchStrength: lightingMatchStrength?.clamp(0.0, 1.0),
          visible: visible,
        ),
      );
      notifyListeners();
      return;
    }
    final items = _state.items.map((item) {
      if (item.id != selectedId) {
        return item;
      }
      final nextCenter = center == null || target == null
          ? (center ?? item.center)
          : Offset(
              center.dx.clamp(0.0, target.width.toDouble()),
              center.dy.clamp(0.0, target.height.toDouble()),
            );
      return item.copyWith(
        center: nextCenter,
        scale: scale?.clamp(0.1, 6.0),
        rotation: rotation,
        flipX: flipX,
        flipY: flipY,
        opacity: opacity?.clamp(0.05, 1.0),
        feather: feather?.clamp(0.0, 40.0),
        colorMatchStrength: colorMatchStrength?.clamp(0.0, 1.0),
        lightingMatchStrength: lightingMatchStrength?.clamp(0.0, 1.0),
        visible: visible,
      );
    }).toList(growable: false);
    _state = _state.copyWith(items: items);
    if (commit) {
      _commitHistory();
    } else {
      notifyListeners();
    }
  }

  void nudgeSelected(Offset delta, {double distance = 1}) {
    final selected = selectedItem;
    if (selected == null) {
      return;
    }
    updateSelectedItem(
      center:
          selected.center + Offset(delta.dx * distance, delta.dy * distance),
      commit: true,
    );
  }

  void duplicateSelected() {
    final selected = selectedItem;
    final target = _state.activeDocument ?? _state.effectiveTargetDocument;
    if (selected == null || target == null) {
      return;
    }
    final duplicate = _engine.duplicate(
      selected,
      Size(target.width.toDouble(), target.height.toDouble()),
    );
    if (_state.pendingItem != null && _state.pendingItem!.id == selected.id) {
      _state = _state.copyWith(
        pendingItem: duplicate,
        selectedItemId: duplicate.id,
      );
      notifyListeners();
      _setStatus('Preview duplicated. Press Confirm when ready.');
      return;
    }
    _state = _state.copyWith(
      items: List<PastedItem>.from(_state.items)..add(duplicate),
      selectedItemId: duplicate.id,
    );
    _commitHistory();
    _setStatus('Layer duplicated.');
  }

  void deleteSelected() {
    final selectedId = _state.selectedItemId;
    if (selectedId == null) {
      return;
    }
    if (_state.pendingItem != null && _state.pendingItem!.id == selectedId) {
      _state = _state.copyWith(clearPendingItem: true, clearSelectedItem: true);
      notifyListeners();
      _setStatus('Preview removed.');
      return;
    }
    _state = _state.copyWith(
      items: _state.items.where((item) => item.id != selectedId).toList(),
      clearSelectedItem: true,
    );
    _commitHistory();
    _setStatus('Layer deleted.');
  }

  void moveSelectedLayerUp() {
    final selectedId = _state.selectedItemId;
    if (selectedId == null ||
        (_state.pendingItem != null && _state.pendingItem!.id == selectedId)) {
      return;
    }
    _state = _state.copyWith(items: _engine.moveUp(_state.items, selectedId));
    _commitHistory();
  }

  void moveSelectedLayerDown() {
    final selectedId = _state.selectedItemId;
    if (selectedId == null ||
        (_state.pendingItem != null && _state.pendingItem!.id == selectedId)) {
      return;
    }
    _state = _state.copyWith(items: _engine.moveDown(_state.items, selectedId));
    _commitHistory();
  }

  void toggleSelectedVisibility() {
    final selected = selectedItem;
    if (selected == null) {
      return;
    }
    updateSelectedItem(visible: !selected.visible, commit: true);
  }

  Future<Uint8List?> exportComposition(
      {bool asPng = true, bool saveToGallery = true}) async {
    final target = _state.activeDocument ?? _state.effectiveTargetDocument;
    if (target == null) {
      _setStatus('Nothing to export yet.');
      return null;
    }
    _state = _state.copyWith(
        isExporting: true, statusMessage: 'Exporting composition...');
    notifyListeners();
    try {
      final bytes = _exportService.export(
        targetDocument: target,
        items: _state.items,
        asPng: asPng,
      );
      if (saveToGallery) {
        await Gal.putImageBytes(bytes,
            name:
                'ai_object_copy_paste_${DateTime.now().millisecondsSinceEpoch}');
      }
      _setStatus(saveToGallery ? 'Exported to gallery.' : 'Export complete.');
      return bytes;
    } catch (_) {
      _setStatus('Export failed.');
      return null;
    } finally {
      _state = _state.copyWith(isExporting: false);
      notifyListeners();
    }
  }

  void undo() {
    final snapshot = _history.undo();
    if (snapshot == null) {
      return;
    }
    _restoreSnapshot(snapshot);
  }

  void redo() {
    final snapshot = _history.redo();
    if (snapshot == null) {
      return;
    }
    _restoreSnapshot(snapshot);
  }

  PastedItem? get selectedItem {
    final selectedId = _state.selectedItemId;
    if (selectedId == null) {
      return null;
    }
    if (_state.pendingItem != null && _state.pendingItem!.id == selectedId) {
      return _state.pendingItem;
    }
    for (final item in _state.items) {
      if (item.id == selectedId) {
        return item;
      }
    }
    return null;
  }

  bool get showItemsOnActiveCanvas => _state.activeDocument != null;

  Rect transformedRect(PastedItem item) => _engine.transformedRect(item);

  @override
  Future<void> dispose() async {
    await _segmentationAdapter.dispose();
    super.dispose();
  }

  SelectionRegion _normalizedSelection(SelectionRegion selection) {
    final document = _state.activeDocument;
    if (document == null) {
      return selection;
    }
    final bounds = selection.bounds;
    final normalized = Rect.fromLTRB(
      bounds.left.clamp(0.0, document.width.toDouble()),
      bounds.top.clamp(0.0, document.height.toDouble()),
      bounds.right.clamp(0.0, document.width.toDouble()),
      bounds.bottom.clamp(0.0, document.height.toDouble()),
    );
    return selection.copyWith(bounds: normalized);
  }

  SelectionMaskData? _shiftedMask(SelectionMaskData? mask, Offset delta) {
    if (mask == null) {
      return null;
    }
    return SelectionMaskData(
      bounds: mask.bounds.shift(delta),
      width: mask.width,
      height: mask.height,
      alpha: List<int>.from(mask.alpha),
    );
  }

  Offset _clampPointToDocument(Offset point, EditorDocument document) {
    return Offset(
      point.dx.clamp(0.0, document.width.toDouble()),
      point.dy.clamp(0.0, document.height.toDouble()),
    );
  }

  Rect _boundsFromPoints(List<Offset> points) {
    var minX = points.first.dx;
    var minY = points.first.dy;
    var maxX = minX;
    var maxY = minY;
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  void _commitHistory() {
    _history.push(_snapshot(_state));
    _syncHistoryFlags();
    notifyListeners();
  }

  void _restoreSnapshot(HistorySnapshot snapshot) {
    _state = _state.copyWith(
      items: snapshot.items,
      selection: snapshot.selection,
      clipboard: snapshot.clipboard,
      pendingItem: snapshot.pendingItem,
      selectedItemId: snapshot.selectedItemId,
    );
    _syncHistoryFlags();
    notifyListeners();
  }

  HistorySnapshot _snapshot(EditorSessionState state) {
    return HistorySnapshot(
      items: List<PastedItem>.from(state.items),
      selection: state.selection,
      clipboard: state.clipboard,
      pendingItem: state.pendingItem,
      selectedItemId: state.selectedItemId,
    );
  }

  void _syncHistoryFlags() {
    _state = _state.copyWith(
      canUndo: _history.canUndo,
      canRedo: _history.canRedo,
    );
  }

  void _setBusy(bool value, String? message) {
    _state = _state.copyWith(isBusy: value, statusMessage: message);
    notifyListeners();
  }

  void _setStatus(String? message) {
    _state = _state.copyWith(statusMessage: message);
    notifyListeners();
  }
}
