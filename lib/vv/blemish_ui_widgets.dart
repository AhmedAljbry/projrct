import 'dart:async';

import 'package:flutter/material.dart';
import 'package:untitled2/vv/blemish_state.dart';

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

class ProcessingOverlay extends StatefulWidget {
  final ProcessingStatus status;
  final double exportProgress;

  const ProcessingOverlay({
    super.key,
    required this.status,
    this.exportProgress = 0.0,
  });

  @override
  State<ProcessingOverlay> createState() => _ProcessingOverlayState();
}

class _ProcessingOverlayState extends State<ProcessingOverlay> {
  Timer? _showTimer;
  bool _showOverlay = false;

  bool get _processing =>
      widget.status == ProcessingStatus.processingPreview ||
      widget.status == ProcessingStatus.processingFinal ||
      widget.status == ProcessingStatus.exporting;

  Duration get _showDelay {
    switch (widget.status) {
      case ProcessingStatus.processingPreview:
        return const Duration(milliseconds: 420);
      case ProcessingStatus.processingFinal:
        return const Duration(milliseconds: 320);
      case ProcessingStatus.exporting:
        return const Duration(milliseconds: 650);
      case ProcessingStatus.idle:
      case ProcessingStatus.error:
        return Duration.zero;
    }
  }

  @override
  void initState() {
    super.initState();
    _syncOverlayVisibility();
  }

  @override
  void didUpdateWidget(covariant ProcessingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      _syncOverlayVisibility();
    }
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    super.dispose();
  }

  void _syncOverlayVisibility() {
    _showTimer?.cancel();

    if (!_processing) {
      if (_showOverlay) {
        setState(() => _showOverlay = false);
      }
      return;
    }

    setState(() => _showOverlay = false);
    final delay = _showDelay;
    if (delay == Duration.zero) {
      setState(() => _showOverlay = true);
      return;
    }

    _showTimer = Timer(delay, () {
      if (mounted && _processing) {
        setState(() => _showOverlay = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_processing && !_showOverlay) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: !_showOverlay,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: _showOverlay ? 1.0 : 0.0,
        child: _showOverlay ? _buildOverlay() : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.26),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.status == ProcessingStatus.exporting) ...[
                SizedBox(
                  width: 200,
                  child: LinearProgressIndicator(
                    value: widget.exportProgress,
                    backgroundColor: const Color(0xFF333333),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF56E39F)),
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Exporting ${(widget.exportProgress * 100).round()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ] else ...[
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF56E39F)),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Healing...',
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
