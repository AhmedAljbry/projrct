import 'package:flutter/foundation.dart';
import 'package:untitled2/vv/blemish_operation.dart';


/// Manages undo/redo history for blemish removal operations.
///
/// Maintains two stacks:
///  - [_undoStack]: operations that have been applied (undo available)
///  - [_redoStack]: operations that were undone (redo available)
///
/// When a new operation is committed, the redo stack is cleared.
class HistoryService extends ChangeNotifier {
  final int maxHistorySize;

  final List<BlemishOperation> _undoStack = [];
  final List<BlemishOperation> _redoStack = [];

  HistoryService({this.maxHistorySize = 50});

  /// All committed operations in application order.
  List<BlemishOperation> get operations => List.unmodifiable(_undoStack);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Commit a new operation. Clears the redo stack.
  void commit(BlemishOperation operation) {
    _undoStack.add(operation);
    _redoStack.clear();

    // Enforce max history: drop oldest operations if over limit.
    if (_undoStack.length > maxHistorySize) {
      _undoStack.removeAt(0);
    }

    notifyListeners();
  }

  /// Undo the most recent operation.
  /// Returns the undone operation, or null if stack is empty.
  BlemishOperation? undo() {
    if (!canUndo) return null;
    final op = _undoStack.removeLast();
    _redoStack.add(op);
    notifyListeners();
    return op;
  }

  /// Redo the most recently undone operation.
  /// Returns the re-committed operation, or null if redo stack is empty.
  BlemishOperation? redo() {
    if (!canRedo) return null;
    final op = _redoStack.removeLast();
    _undoStack.add(op);
    notifyListeners();
    return op;
  }

  /// Peek at the last committed operation without removing it.
  BlemishOperation? get lastOperation =>
      _undoStack.isNotEmpty ? _undoStack.last : null;

  /// Clear all history. Used on session reset.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  /// Replace the entire history (e.g., when loading a saved session).
  void loadHistory(List<BlemishOperation> operations) {
    _undoStack.clear();
    _redoStack.clear();
    _undoStack.addAll(operations.take(maxHistorySize));
    notifyListeners();
  }

  /// Snapshot of operations for serialization.
  List<Map<String, dynamic>> toJson() =>
      _undoStack.map((op) => op.toJson()).toList();

  static List<BlemishOperation> operationsFromJson(List<Map<String, dynamic>> json) =>
      json.map((j) => BlemishOperation.fromJson(j)).toList();
}
