import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class LamaCompareSlider extends StatefulWidget {
  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;
  final double borderRadius;

  const LamaCompareSlider({
    super.key,
    required this.before,
    required this.after,
    this.beforeLabel = 'Before',
    this.afterLabel = 'After',
    this.borderRadius = 24,
  });

  @override
  State<LamaCompareSlider> createState() => _LamaCompareSliderState();
}

class _LamaCompareSliderState extends State<LamaCompareSlider> {
  double _split = 0.52;

  void _update(Offset localPosition, double width) {
    setState(() {
      _split = (localPosition.dx / width).clamp(0.1, 0.9);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sliderX = constraints.maxWidth * _split;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _update(details.localPosition, constraints.maxWidth),
          onHorizontalDragUpdate: (details) =>
              _update(details.localPosition, constraints.maxWidth),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(child: widget.after),
                Positioned.fill(
                  child: ClipRect(
                    clipper: _SplitClipper(_split),
                    child: widget.before,
                  ),
                ),
                PositionedDirectional(
                  top: 14,
                  start: 14,
                  child: _CompareLabel(
                    label: widget.beforeLabel,
                    color: Colors.white,
                  ),
                ),
                PositionedDirectional(
                  top: 14,
                  end: 14,
                  child: _CompareLabel(
                    label: widget.afterLabel,
                    color: LamaTheme.accent,
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: sliderX - 1.5,
                  child: Container(
                    width: 3,
                    color: Colors.white,
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: sliderX - 24,
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: LamaTheme.accent,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.compare_arrows_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplitClipper extends CustomClipper<Rect> {
  final double split;

  const _SplitClipper(this.split);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * split, size.height);

  @override
  bool shouldReclip(covariant _SplitClipper oldClipper) =>
      oldClipper.split != split;
}

class _CompareLabel extends StatelessWidget {
  final String label;
  final Color color;

  const _CompareLabel({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.46),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
