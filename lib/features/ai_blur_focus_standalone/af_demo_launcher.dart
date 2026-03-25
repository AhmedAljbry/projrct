import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'presentation/screen/ai_blur_focus_screen.dart';

/// Standalone demo launcher.
///
/// Push this route independently from anywhere in the app:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(builder: (_) => const AfDemoLauncher()),
/// );
/// ```
///
/// Or for production use, push [AiBlurFocusScreen] directly with a real image:
///
/// ```dart
/// Navigator.of(context).push(
///   MaterialPageRoute(
///     builder: (_) => AiBlurFocusScreen(
///       initialImage: myUiImage,
///       onApply: (bytes) { /* save bytes */ },
///     ),
///   ),
/// );
/// ```
class AfDemoLauncher extends StatefulWidget {
  const AfDemoLauncher({super.key});

  @override
  State<AfDemoLauncher> createState() => _AfDemoLauncherState();
}

class _AfDemoLauncherState extends State<AfDemoLauncher> {
  bool _loading = true;
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadDemo();
  }

  Future<void> _loadDemo() async {
    // Generate a 800×600 gradient demo image so the screen
    // works without any asset file.
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const w = 800.0, h = 600.0;

    // Background gradient
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2A3A), Color(0xFF0D1117)],
        ).createShader(const Rect.fromLTWH(0, 0, w, h)),
    );

    // Simulated portrait silhouette (ellipse in centre)
    canvas.drawOval(
      const Rect.fromLTWH(280, 80, 240, 440),
      Paint()
        ..color = const Color(0xFF2E4A6A)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30),
    );
    canvas.drawOval(
      const Rect.fromLTWH(300, 100, 200, 380),
      Paint()..color = const Color(0xFF3A5A7A),
    );

    // Foreground detail circles
    for (var i = 0; i < 12; i++) {
      canvas.drawCircle(
        Offset(60.0 + i * 62, 540),
        22,
        Paint()..color = const Color(0xFF56E39F).withValues(alpha: 0.18),
      );
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(w.round(), h.round());
    if (mounted) {
      setState(() {
        _image = img;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _image == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0C0C0E),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF56E39F)),
        ),
      );
    }

    return AiBlurFocusScreen(
      initialImage: _image!,
      onApply: (Uint8List bytes) {
        debugPrint('[AfDemo] Applied — ${bytes.length} bytes');
        // In production, pass bytes to your save/share pipeline.
      },
      onClose: () {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      },
    );
  }
}
