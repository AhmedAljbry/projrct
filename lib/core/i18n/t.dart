// t.dart
// ─────────────────────────────────────────────────────────────────────────────
// Bridge: maps the legacy T/Lang API onto the centralized AppL10n system so
// that existing call-sites compile without any changes.
//
// Usage (in widgets that have a BuildContext):
//   final t = T.of(context);
//   t.of('some_key')  → same as AppL10n.of(context).get('some_key')
//   t.isRTL           → locale is Arabic
//   t.locale          → current Locale
//
// Usage in FilterStudioStylePreset.name(Lang lang):
//   Lang.ar / Lang.en  → language discriminator
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import 'package:untitled2/core/ui/AppL10n.dart';

/// Language discriminator used by model classes (e.g. FilterStudioStylePreset).
enum Lang { en, ar }

/// Thin wrapper around [AppL10n] that provides the legacy `T.of()` / `.of(key)`
/// interface and exposes helpers used across the UI layer.
class T {
  final AppL10n _l10n;

  const T._(this._l10n);

  // ── Factory ───────────────────────────────────────────────────────────────

  /// Obtain a [T] from the nearest [AppL10n] in the widget tree.
  static T from(BuildContext context) => T._(AppL10n.of(context));

  // ── Key lookup ────────────────────────────────────────────────────────────

  /// Look up a localized string by [key].
  String call(String key) => _l10n.get(key);

  /// Named alias so existing `t.of('key')` call-sites continue to work.
  String of(String key) => _l10n.get(key);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns `true` when the active locale is Arabic (RTL).
  bool get isRTL => _l10n.isAr;

  /// The underlying [Locale].
  Locale get locale => _l10n.locale;

  /// The underlying [AppL10n] instance (for call-sites that need the whole
  /// object, e.g. `_t.locale`).
  AppL10n get l10n => _l10n;
}
