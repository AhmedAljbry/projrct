import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

class HeroCanvasSection extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;

  final bool compareEnabled;
  final double compareSplit;
  final ValueChanged<double> onCompareSplitChanged;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  const HeroCanvasSection({
    super.key,
    required this.mode,
    required this.status,
    required this.compareEnabled,
    required this.compareSplit,
    required this.onCompareSplitChanged,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
  });

  @override
  Widget build(BuildContext context) {
    final canvas = _CanvasSurface(
      child: _CompareCanvasView(
        mode: mode,
        status: status,
        compareEnabled: compareEnabled,
        compareSplit: compareSplit,
        beforeImage: beforeImage,
        afterImage: afterImage,
        emptyCanvas: emptyCanvas,
        onCompareSplitChanged: onCompareSplitChanged,
      ),
    );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.r20),
            child: canvas,
          ),
        ),
      ),
    );
  }
}

class _CanvasSurface extends StatelessWidget {
  final Widget child;

  const _CanvasSurface({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.55),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppTokens.r20),
      ),
      child: child,
    );
  }
}

class _CompareCanvasView extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;

  final bool compareEnabled;
  final double compareSplit;
  final ValueChanged<double> onCompareSplitChanged;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  const _CompareCanvasView({
    required this.mode,
    required this.status,
    required this.compareEnabled,
    required this.compareSplit,
    required this.onCompareSplitChanged,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;

        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1,
                maxScale: 4,
                boundaryMargin: const EdgeInsets.all(20),
                child: SizedBox.expand(
                  child: _CanvasContent(
                    mode: mode,
                    status: status,
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    emptyCanvas: emptyCanvas,
                    compareEnabled: compareEnabled,
                    compareSplit: compareSplit,
                  ),
                ),
              ),
            ),

            // Compare interaction layer: gesture only when compare is enabled.
            if (compareEnabled) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (d) {
                    final next = (d.localPosition.dx / w).clamp(0.12, 0.88);
                    onCompareSplitChanged(next);
                  },
                ),
              ),

              _CompareHandle(
                split: compareSplit,
              ),
            ],

            Positioned(
              left: 14,
              bottom: 14,
              child: _HintChip(
                visible: compareEnabled,
                icon: Icons.drag_indicator_rounded,
                text: 'Drag to compare',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CanvasContent extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  final bool compareEnabled;
  final double compareSplit;

  const _CanvasContent({
    required this.mode,
    required this.status,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
    required this.compareEnabled,
    required this.compareSplit,
  });

  @override
  Widget build(BuildContext context) {
    final after = afterImage != null
        ? Image(image: afterImage!, fit: BoxFit.cover)
        : (emptyCanvas ??
            _FallbackCanvas(
              title: mode == UnifiedEditorMode.architect ? 'Render Preview' : 'Photo Preview',
            ));

    final before = beforeImage != null
        ? Image(image: beforeImage!, fit: BoxFit.cover)
        : (emptyCanvas ??
            _FallbackCanvas(
              title: 'Original',
              accent: AppTokens.info,
            ));

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base = result / after.
        after,

        // Overlay = original / before when compare is enabled.
        if (compareEnabled)
          ClipRect(
            clipper: _SplitClipper(compareSplit),
            child: before,
          ),

        // Overlays: region selection highlight, smart mask fill, and architect tags.
        Positioned.fill(
          child: _OverlayStack(mode: mode, status: status),
        ),
      ],
    );
  }
}

class _OverlayStack extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;

  const _OverlayStack({required this.mode, required this.status});

  @override
  Widget build(BuildContext context) {
    final showRegion = status.regionSelected;
    final showMask = status.maskReady && (mode == UnifiedEditorMode.pro || mode == UnifiedEditorMode.architect || mode == UnifiedEditorMode.quick);
    final showArchitectTags = mode == UnifiedEditorMode.architect && status.materialDetected;

    return Stack(
      children: [
        if (showRegion)
          Center(
            child: Container(
              width: 220,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppTokens.primary.withValues(alpha: 0.75), width: 2),
                boxShadow: AppTokens.primaryGlow(0.22),
              ),
              child: const SizedBox.shrink(),
            ),
          ),

        if (showMask)
          CustomPaint(
            painter: _SmartMaskPainter(color: AppTokens.primary.withValues(alpha: 0.18)),
            size: Size.infinite,
          ),

        if (showArchitectTags) ...[
          const Positioned(
            top: 18,
            left: 18,
            child: _TagPill(icon: Icons.layers_rounded, label: 'Concrete'),
          ),
          const Positioned(
            top: 56,
            left: 18,
            child: _TagPill(icon: Icons.auto_mode_rounded, label: 'Neutrality'),
          ),
        ],

        // Sample anchors: source vs target points.
        Positioned(
          left: 34,
          bottom: 92,
          child: _AnchorPoint(color: AppTokens.info, label: 'S'),
        ),
        Positioned(
          right: 34,
          top: 92,
          child: _AnchorPoint(color: AppTokens.primary, label: 'T'),
        ),
      ],
    );
  }
}

class _AnchorPoint extends StatelessWidget {
  final Color color;
  final String label;

  const _AnchorPoint({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: Border.all(color: Colors.black.withValues(alpha: 0.35), width: 2),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TagPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTokens.primary.withValues(alpha: 0.26), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTokens.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartMaskPainter extends CustomPainter {
  final Color color;

  _SmartMaskPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // A soft blob to simulate the smart mask fill.
    final center = Offset(size.width * 0.52, size.height * 0.52);
    final radius = math.min(size.width, size.height) * 0.26;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final blob = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius))
      ..close();

    canvas.drawPath(blob, paint);

    // Slight edge glow.
    final edge = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(blob, edge);
  }

  @override
  bool shouldRepaint(covariant _SmartMaskPainter oldDelegate) => oldDelegate.color != color;
}

class _FallbackCanvas extends StatelessWidget {
  final String title;
  final Color? accent;

  const _FallbackCanvas({required this.title, this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            (accent ?? AppTokens.primary).withValues(alpha: 0.22),
            AppTokens.surface.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_size_select_actual_rounded,
                color: accent ?? AppTokens.primary, size: 42),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                color: AppTokens.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double split;

  _SplitClipper(this.split);

  @override
  Rect getClip(Size size) {
    final w = size.width * split;
    return Rect.fromLTWH(0, 0, w, size.height);
  }

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) => oldClipper.split != split;
}

class _CompareHandle extends StatelessWidget {
  final double split;

  const _CompareHandle({required this.split});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final x = constraints.maxWidth * split;
        return Stack(
          children: [
            Positioned(
              top: 0,
              bottom: 0,
              left: x - 1.5,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.82),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.36),
                      blurRadius: 16,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: x - 22,
              child: Center(
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppTokens.primaryGradient,
                    boxShadow: AppTokens.primaryGlow(0.25),
                  ),
                  child: const Icon(
                    Icons.drag_indicator_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HintChip extends StatelessWidget {
  final bool visible;
  final IconData icon;
  final String text;

  const _HintChip({
    required this.visible,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTokens.primary.withValues(alpha: 0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTokens.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppTokens.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

