import 'package:flutter/material.dart';

import '../cubit/blur_photo_state.dart';

const _kAccent = Color(0xFF56E39F);

/// Top bar: close (left), title (centre), download + undo (right).
class BpTopBar extends StatelessWidget {
  const BpTopBar({
    super.key,
    required this.status,
    required this.canUndo,
    required this.onClose,
    required this.onExport,
    required this.onUndo,
    required this.onCompareStart,
    required this.onCompareEnd,
  });

  final BpEditorStatus status;
  final bool canUndo;
  final VoidCallback onClose;
  final VoidCallback onExport;
  final VoidCallback? onUndo;
  final VoidCallback onCompareStart;
  final VoidCallback onCompareEnd;

  @override
  Widget build(BuildContext context) {
    final exporting = status == BpEditorStatus.exporting;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(children: [
          // Close
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            tooltip: 'Close',
          ),
          // Title
          const Expanded(
            child: Text(
              'Blur Photo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // Undo
          if (canUndo)
            IconButton(
              onPressed: onUndo,
              icon: const Icon(Icons.undo_rounded, color: Colors.white70, size: 24),
              tooltip: 'Undo',
            ),
          // Compare (long press)
          GestureDetector(
            onLongPressStart: (_) => onCompareStart(),
            onLongPressEnd: (_) => onCompareEnd(),
            child: Tooltip(
              message: 'Hold to compare',
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Icon(
                  Icons.compare_rounded,
                  color: Colors.white54,
                  size: 24,
                ),
              ),
            ),
          ),
          // Export / save
          IconButton(
            onPressed: exporting ? null : onExport,
            icon: Icon(
              Icons.file_download_outlined,
              color: exporting ? Colors.white24 : _kAccent,
              size: 28,
            ),
            tooltip: 'Save',
          ),
        ]),
      ),
    );
  }
}
