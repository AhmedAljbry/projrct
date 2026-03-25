import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/i18n/t.dart';
import '../../application/inpainting_bloc/inpainting_bloc.dart';
import '../../application/inpainting_bloc/inpainting_event.dart';
import '../../application/inpainting_bloc/inpainting_state.dart';
import '../../domain/inpainting_status.dart';

// ═══════════════════════════════════════════════════════════════
//  Design tokens (mirrors pro_tool_panel.dart)
// ═══════════════════════════════════════════════════════════════
const _accent   = Color(0xFF00E5C8);
const _surface  = Color(0xF0101820);  // near-opaque dark
const _text1    = Color(0xFFECF0F4);
const _text2    = Color(0xFF6B7E8F);
const _border   = Color(0xFF1E2A36);
const _danger   = Color(0xFFFF5252);

// ═══════════════════════════════════════════════════════════════
//  ProcessingOverlay
//
//  Animated modal that covers the editor while the job runs.
//  Shows:
//    uploading  → spinner + "جاري الرفع"
//    queued     → pulse ring + queue position
//    processing → arc progress ring + percentage + stage
//    downloading→ spinner + "جاري التحميل"
// ═══════════════════════════════════════════════════════════════
class ProcessingOverlay extends StatelessWidget {
  final T t;
  final VoidCallback? onCancel;

  const ProcessingOverlay({super.key, required this.t, this.onCancel});

  static bool _isActive(InpaintingStatus s) =>
      s == InpaintingStatus.uploading ||
          s == InpaintingStatus.queued    ||
          s == InpaintingStatus.processing||
          s == InpaintingStatus.downloading;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InpaintingBloc, InpaintingState>(
      builder: (context, state) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          child: _isActive(state.status)
              ? _OverlayBody(
            key:      const ValueKey('active'),
            t:        t,
            state:    state,
            onCancel: onCancel ??
                    () => context
                    .read<InpaintingBloc>()
                    .add(InpaintingCancel()),
          )
              : SizedBox.shrink(key: ValueKey('hidden')),
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────
class _OverlayBody extends StatelessWidget {
  final T t;
  final InpaintingState state;
  final VoidCallback onCancel;

  const _OverlayBody(
      {super.key,
        required this.t,
        required this.state,
        required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            color: Colors.black.withValues(alpha: 0.62),
            child: Center(
              child: _Card(t: t, state: state, onCancel: onCancel),
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
//  Card
// ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final T t;
  final InpaintingState state;
  final VoidCallback onCancel;

  const _Card(
      {required this.t, required this.state, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin:  EdgeInsets.symmetric(horizontal: 36),
      padding: EdgeInsets.fromLTRB(28, 32, 28, 24),
      decoration: BoxDecoration(
        color:        _surface,
        borderRadius: BorderRadius.circular(28),
        border:       Border.all(color: _border.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color:      _accent.withValues(alpha: 0.12),
            blurRadius: 60,
            spreadRadius: 4,
          ),
          BoxShadow(
            color:      Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Progress indicator ──────────────────────────
          _ProgressRing(state: state),
          SizedBox(height: 24),

          // ── Stage label ─────────────────────────────────
          Text(
            _stageLabel(state, t),
            textAlign: TextAlign.center,
            style: TextStyle(
              color:      _text1,
              fontSize:   17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),

          // ── Server message ──────────────────────────────
          if ((state.serverMessage ?? '').isNotEmpty) ...[
            SizedBox(height: 6),
            Text(
              state.serverMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color:    _text2,
                fontSize: 13,
                height:   1.4,
              ),
            ),
          ],

          // ── Poll / elapsed ──────────────────────────────
          if (state.pollCount > 0) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Poll #${state.pollCount}',
                style: TextStyle(
                    color: _text2, fontSize: 11),
              ),
            ),
          ],

          SizedBox(height: 28),
          const Divider(color: _border, height: 1),
          SizedBox(height: 16),

          // ── Cancel button ───────────────────────────────
          GestureDetector(
            onTap: onCancel,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: _danger.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _danger.withValues(alpha: 0.22)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_circle_outlined,
                      color: _danger.withValues(alpha: 0.85), size: 18),
                  SizedBox(width: 8),
                  Text(
                    t.of('cancel'),
                    style: TextStyle(
                      color:      _danger.withValues(alpha: 0.85),
                      fontWeight: FontWeight.w700,
                      fontSize:   14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _stageLabel(InpaintingState s, T t) => switch (s.status) {
    InpaintingStatus.uploading   => 'جاري الرفع...',
    InpaintingStatus.queued      => s.queuePosition != null
        ? 'في الطابور — المركز ${s.queuePosition}'
        : 'في الطابور...',
    InpaintingStatus.processing  => s.serverStage == 'saving'
        ? 'جاري الحفظ...'
        : 'جاري المعالجة...',
    InpaintingStatus.downloading => 'جاري التحميل...',
    _                            => '...',
  };
}

// ──────────────────────────────────────────────────────────────
//  Progress ring
// ──────────────────────────────────────────────────────────────
class _ProgressRing extends StatefulWidget {
  final InpaintingState state;
  const _ProgressRing({required this.state});

  @override
  State<_ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<_ProgressRing>
    with TickerProviderStateMixin {
  late final AnimationController _spinCtrl;
  late final AnimationController _progCtrl;
  late Animation<double> _progAnim;

  double _lastProgress = 0;

  @override
  void initState() {
    super.initState();
    _spinCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _progCtrl = AnimationController(
      vsync:    this,
      duration: const Duration(milliseconds: 600),
    );
    _progAnim = Tween<double>(begin: 0, end: 0).animate(_progCtrl);
  }

  @override
  void didUpdateWidget(covariant _ProgressRing old) {
    super.didUpdateWidget(old);
    final p = (widget.state.serverProgress ?? 0).toDouble();
    if (p != _lastProgress) {
      _progAnim = Tween<double>(begin: _lastProgress / 100, end: p / 100)
          .animate(CurvedAnimation(parent: _progCtrl, curve: Curves.easeOut));
      _progCtrl.forward(from: 0);
      _lastProgress = p;
    }
  }

  @override
  void dispose() {
    _spinCtrl.dispose();
    _progCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.state.serverProgress ?? 0;
    final hasProgress = widget.state.status == InpaintingStatus.processing &&
        progress > 0;

    return SizedBox(
      width:  80,
      height: 80,
      child: AnimatedBuilder(
        animation: Listenable.merge([_spinCtrl, _progCtrl]),
        builder: (_, __) => CustomPaint(
          painter: _RingPainter(
            progress:    hasProgress ? _progAnim.value : null,
            spinAngle:   _spinCtrl.value * 2 * math.pi,
            accent:      _accent,
            trackColor:  _border,
          ),
          child: Center(
            child: hasProgress
                ? Text(
              '$progress%',
              style: TextStyle(
                color:      _text1,
                fontSize:   15,
                fontWeight: FontWeight.w900,
              ),
            )
                : Container(
              width:  12,
              height: 12,
              decoration: BoxDecoration(
                shape:  BoxShape.circle,
                color:  _accent,
                boxShadow: [
                  BoxShadow(
                    color:      _accent.withValues(alpha: 0.8),
                    blurRadius: 10,
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double? progress;  // 0..1, null = indeterminate
  final double spinAngle;
  final Color accent;
  final Color trackColor;

  const _RingPainter({
    required this.progress,
    required this.spinAngle,
    required this.accent,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r  = (size.width - 10) / 2;

    final trackPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..color       = trackColor
      ..strokeWidth = 4
      ..strokeCap   = StrokeCap.round;

    final arcPaint = Paint()
      ..style       = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap   = StrokeCap.round
      ..shader      = SweepGradient(
        colors:     [accent.withValues(alpha: 0.2), accent],
        startAngle: 0,
        endAngle:   2 * math.pi,
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: r));

    // Track
    canvas.drawCircle(Offset(cx, cy), r, trackPaint);

    if (progress != null) {
      // Determinate arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        -math.pi / 2,
        2 * math.pi * progress!,
        false,
        arcPaint,
      );
    } else {
      // Indeterminate spinning arc
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r),
        spinAngle,
        math.pi * 1.2,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress  != progress  ||
          old.spinAngle != spinAngle;
}
