import 'package:flutter/material.dart';
import 'package:untitled2/vv/blemish_state.dart';


/// Toggle button to switch between before/after views.
class CompareToggleButton extends StatelessWidget {
  final CompareMode mode;
  final ValueChanged<CompareMode> onChanged;

  const CompareToggleButton({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onChanged(mode == CompareMode.edited ? CompareMode.original : CompareMode.edited);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: mode == CompareMode.original
              ? const Color(0xFF56E39F).withValues(alpha: 0.18)
              : Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: mode == CompareMode.original
                ? const Color(0xFF56E39F)
                : Colors.white24,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              mode == CompareMode.original ? Icons.visibility : Icons.compare,
              color: mode == CompareMode.original
                  ? const Color(0xFF56E39F)
                  : Colors.white70,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              mode == CompareMode.original ? 'Original' : 'Compare',
              style: TextStyle(
                color: mode == CompareMode.original
                    ? const Color(0xFF56E39F)
                    : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen dimming overlay shown while processing.
class ProcessingOverlay extends StatelessWidget {
  final ProcessingStatus status;
  final double exportProgress;

  const ProcessingOverlay({
    super.key,
    required this.status,
    this.exportProgress = 0.0,
  });

  bool get _visible =>
      status == ProcessingStatus.processingPreview ||
      status == ProcessingStatus.processingFinal ||
      status == ProcessingStatus.exporting;

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
      color: Colors.black.withValues(alpha: 0.42),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (status == ProcessingStatus.exporting) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: exportProgress,
                    backgroundColor: const Color(0xFF333333),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56E39F)),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exporting ${(exportProgress * 100).round()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ] else ...[
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF56E39F)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Healing…',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Error snack-bar content displayed on engine errors.
class BlemishErrorBar extends StatelessWidget {
  final String? message;
  final VoidCallback? onDismiss;

  const BlemishErrorBar({super.key, this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFF4444).withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message!,
                style: const TextStyle(color: Color(0xFFFFAAAA), fontSize: 12),
              ),
            ),
            const Icon(Icons.close, color: Color(0xFFFF6B6B), size: 16),
          ],
        ),
      ),
    );
  }
}
