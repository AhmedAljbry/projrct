import '../domain/entities/editor_models.dart';

class HistoryManager {
  final List<HistorySnapshot> _undo = <HistorySnapshot>[];
  final List<HistorySnapshot> _redo = <HistorySnapshot>[];

  bool get canUndo => _undo.length > 1;
  bool get canRedo => _redo.isNotEmpty;

  void reset(HistorySnapshot snapshot) {
    _undo
      ..clear()
      ..add(snapshot);
    _redo.clear();
  }

  void push(HistorySnapshot snapshot) {
    if (_undo.isNotEmpty && identical(_undo.last, snapshot)) {
      return;
    }
    _undo.add(snapshot);
    _redo.clear();
  }

  HistorySnapshot? undo() {
    if (_undo.length <= 1) {
      return null;
    }
    final current = _undo.removeLast();
    _redo.add(current);
    return _undo.last;
  }

  HistorySnapshot? redo() {
    if (_redo.isEmpty) {
      return null;
    }
    final snapshot = _redo.removeLast();
    _undo.add(snapshot);
    return snapshot;
  }
}
