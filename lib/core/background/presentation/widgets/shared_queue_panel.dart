import 'package:flutter/material.dart';

import 'package:untitled2/core/background/presentation/widgets/operations_queue_view.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_studio_chrome.dart';

class SharedQueuePanel extends StatelessWidget {
  const SharedQueuePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: InpaintingStudioTheme.surfaceStrong,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      child: const OperationsQueueView(compact: true),
    );
  }
}
