import 'package:flutter/material.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class LamaStatusIndicator extends StatelessWidget {
  final int progress;
  final String message;
  final bool isProcessing;

  const LamaStatusIndicator({
    super.key,
    required this.progress,
    required this.message,
    this.isProcessing = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                value: isProcessing ? (progress / 100).clamp(0.0, 1.0) : null,
                color: LamaTheme.accent,
                strokeWidth: 5,
                backgroundColor: Colors.white12,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isProcessing ? '$progress%' : 'Preparing...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isProcessing ? message : 'Uploading...',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
