import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class BeforeAfterSlider extends StatefulWidget {
  const BeforeAfterSlider({
    super.key,
    required this.beforeBytes,
    required this.afterBytes,
    this.aspectRatio = 16 / 10,
    this.borderRadius = 24,
  });

  final Uint8List beforeBytes;
  final Uint8List afterBytes;
  final double aspectRatio;
  final double borderRadius;

  @override
  State<BeforeAfterSlider> createState() => _BeforeAfterSliderState();
}

class _BeforeAfterSliderState extends State<BeforeAfterSlider> {
  double _position = 0.52;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              _position =
                  ((_position * width) + details.delta.dx).clamp(0.0, width) /
                      width;
            });
          },
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Image.memory(widget.beforeBytes, fit: BoxFit.cover),
                  ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _position,
                      child: Image.memory(widget.afterBytes, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    left: (_position * width).clamp(14.0, width - 14.0) - 1.5,
                    top: 0,
                    bottom: 0,
                    child: Container(
                      width: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[
                            Colors.white.withValues(alpha: 0.18),
                            Colors.white.withValues(alpha: 0.96),
                            Colors.white.withValues(alpha: 0.18),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.28),
                            blurRadius: 14,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (_position * width).clamp(28.0, width - 28.0) - 24,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.white.withValues(alpha: 0.18),
                              ViralStudioTokens.background
                                  .withValues(alpha: 0.84),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.82),
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.28),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const <Widget>[
                            Icon(Icons.chevron_left_rounded,
                                color: Colors.white),
                            Icon(Icons.chevron_right_rounded,
                                color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: _Tag(label: 'Before'),
                  ),
                  Positioned(
                    right: 16,
                    top: 16,
                    child: _Tag(label: 'After'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: ViralStudioTokens.background.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
