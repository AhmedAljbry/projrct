import 'package:flutter/material.dart';

import 'inpainting_studio_chrome.dart';

class BeforeAfterSlider extends StatefulWidget {
  final Widget before;
  final Widget after;
  final String beforeLabel;
  final String afterLabel;
  final double borderRadius;

  const BeforeAfterSlider({
    super.key,
    required this.before,
    required this.after,
    required this.beforeLabel,
    required this.afterLabel,
    this.borderRadius = 28,
  });

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _split = 0.56;

  void _updateSplit(Offset localPosition, double width) {
    setState(() {
      _split = (localPosition.dx / width).clamp(0.12, 0.88);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final sliderX = width * _split;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _updateSplit(details.localPosition, width),
          onHorizontalDragUpdate: (details) =>
              _updateSplit(details.localPosition, width),
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
                  top: 16,
                  start: 16,
                  child: _SliderLabel(
                    label: widget.beforeLabel,
                    accent: InpaintingStudioTheme.cyan,
                  ),
                ),
                PositionedDirectional(
                  top: 16,
                  end: 16,
                  child: _SliderLabel(
                    label: widget.afterLabel,
                    accent: InpaintingStudioTheme.mint,
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: sliderX - 1.5,
                  child: Container(
                    width: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x66000000),
                          blurRadius: 14,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: sliderX - 22,
                  child: Center(
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: InpaintingStudioTheme.primaryGradient,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x5538E7B5),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.drag_indicator_rounded,
                        color: Colors.black,
                        size: 20,
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
  bool shouldReclip(covariant _SplitClipper oldClipper) {
    return oldClipper.split != split;
  }
}

class _SliderLabel extends StatelessWidget {
  final String label;
  final Color accent;

  const _SliderLabel({
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
