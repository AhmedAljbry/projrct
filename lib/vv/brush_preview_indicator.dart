import 'package:flutter/material.dart';
import 'package:untitled2/vv/brush_settings.dart';


/// معاينة الفرشاة الثابتة أسفل الشاشة.
/// تظهر حجم + نعومة الفرشاة الحالية بدون أي حركة.
class BrushPreviewIndicator extends StatelessWidget {
  final BrushSettings settings;

  const BrushPreviewIndicator({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    // الحد الأقصى للعرض المرئي 60px radius
    final displayRadius = settings.radius.clamp(8.0, 60.0);

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E0E),
        border: Border(
          top: BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
        ),
      ),
      child: Center(
        child: SizedBox(
          width:  displayRadius * 2 + 12,
          height: displayRadius * 2 + 12,
          child: CustomPaint(
            painter: _BrushPreviewPainter(
              radius:   displayRadius,
              softness: settings.softness,
            ),
          ),
        ),
      ),
    );
  }
}

class _BrushPreviewPainter extends CustomPainter {
  final double radius;
  final double softness;

  const _BrushPreviewPainter({required this.radius, required this.softness});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // تدرج داخلي ناعم
    if (softness > 0.05) {
      final stopInner = (1.0 - softness).clamp(0.0, 0.95);
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.35),
              Colors.white.withValues(alpha: 0.0),
            ],
            stops: [stopInner, 1.0],
          ).createShader(
            Rect.fromCircle(center: center, radius: radius),
          ),
      );
    }

    // Ring خارجي
    canvas.drawCircle(
      center, radius,
      Paint()
        ..color       = Colors.white.withValues(alpha: 0.85)
        ..style       = PaintingStyle.stroke
        ..strokeWidth = 1.6,
    );

    // Ring feather (أخضر)
    if (softness > 0.05) {
      canvas.drawCircle(
        center,
        radius * (1.0 - softness),
        Paint()
          ..color       = const Color(0xFF56E39F).withValues(alpha: 0.55)
          ..style       = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // نقطة المركز
    canvas.drawCircle(center, 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _BrushPreviewPainter o) =>
      o.radius != radius || o.softness != softness;
}
