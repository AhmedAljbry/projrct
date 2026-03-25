import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'editor_engine_controller.dart';

/// Persists non-image tuning (pack, Pro sliders, mask kind) across sessions.
class UnifiedEditorSessionStore {
  static const _key = 'unified_editor_workspace_session_v1';

  static Future<void> restore(EditorEngineController c) async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final m = jsonDecode(raw);
      if (m is Map<String, dynamic>) {
        c.restoreSessionMap(m);
      }
    } catch (_) {}
  }

  static Future<void> save(EditorEngineController c) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_key, jsonEncode(c.toSessionMap()));
  }
}
