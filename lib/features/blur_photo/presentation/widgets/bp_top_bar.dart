import 'package:flutter/material.dart';

import '../cubit/blur_photo_state.dart';

const _kAccent = Color(0xFF56E39F);

class BpTopBar extends StatelessWidget {
  const BpTopBar({
    super.key,
    required this.status,
    required this.onClose,
    required this.onExport,
  });

  final BpEditorStatus status;
  final VoidCallback onClose;
  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    final exporting = status == BpEditorStatus.exporting;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
        child: Row(
          children: [
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              tooltip: 'Close',
            ),
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
            IconButton(
              onPressed: exporting ? null : onExport,
              icon: Icon(
                Icons.file_download_outlined,
                color: exporting ? Colors.white24 : _kAccent,
                size: 28,
              ),
              tooltip: 'Save',
            ),
          ],
        ),
      ),
    );
  }
}
