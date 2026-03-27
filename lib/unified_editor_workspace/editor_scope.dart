import 'package:flutter/material.dart';

import 'editor_engine_controller.dart';

/// Provides [EditorEngineController] to context panels and rails.
class EditorScope extends InheritedNotifier<EditorEngineController> {
  const EditorScope({
    super.key,
    required EditorEngineController controller,
    required super.child,
  }) : super(notifier: controller);

  static EditorEngineController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<EditorScope>();
    assert(scope != null, 'EditorScope missing');
    return scope!.notifier!;
  }

  static EditorEngineController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<EditorScope>()?.notifier;
  }
}
