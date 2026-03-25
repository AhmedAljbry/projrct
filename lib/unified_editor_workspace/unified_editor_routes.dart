import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'unified_editor_workspace.dart';

/// Opens the unified creative studio (optionally with pre-loaded image bytes).
void openUnifiedEditorWorkspace(
  BuildContext context, {
  Uint8List? sourceImageBytes,
  String title = 'Unified Creative Studio',
}) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => UnifiedEditorWorkspace(
        title: title,
        sourceImageBytes: sourceImageBytes,
      ),
    ),
  );
}
