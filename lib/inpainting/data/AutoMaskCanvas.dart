import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;



class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mask + Inpainting Test',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const TestHubPage(),
    );
  }
}

// =========================================================
// 0) شاشة مركزية للتنقل بين شاشات الاختبار
// =========================================================
class TestHubPage extends StatelessWidget {
  const TestHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        title: Text('Test Hub'),
        backgroundColor: Colors.transparent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _NavCard(
              title: '1) Test Auto Select (SAM) - Mock',
              subtitle: 'انقر على الصورة → يظهر ماسك وهمي فوق الصورة',
              icon: Icons.select_all,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TestAutoMaskPage()),
              ),
            ),
            SizedBox(height: 12),
            _NavCard(
              title: '2) Server Integration Test (SAM + LaMa) - Mock',
              subtitle: 'انقر لتوليد ماسك → زر تنفيذ يظهر → محاكاة مسح',
              icon: Icons.auto_fix_high,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ServerTestPage()),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'ملاحظة: الآن كل شيء Mock. لاحقًا تستبدل دوال mock بطلبات API حقيقية.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF161D27),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7))),
                ],
              ),
            ),
            Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 1) صفحة تجربة Auto Select (SAM) - Mock
// =========================================================
class TestAutoMaskPage extends StatefulWidget {
  const TestAutoMaskPage({super.key});

  @override
  State<TestAutoMaskPage> createState() => _TestAutoMaskPageState();
}

class _TestAutoMaskPageState extends State<TestAutoMaskPage> {
  ui.Image? _testImage;
  bool _isLoadingImage = true;

  @override
  void initState() {
    super.initState();
    _loadSampleImage();
  }

  Future<void> _loadSampleImage() async {
    setState(() => _isLoadingImage = true);
    try {
      final response = await http
          .get(Uri.parse('https://picsum.photos/800/600'))
          .timeout(const Duration(seconds: 10));
      final bytes = response.bodyBytes;
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) return;
      setState(() {
        _testImage = frame.image;
        _isLoadingImage = false;
      });
    } catch (e) {
      debugPrint('🚨 Error loading image: $e');
      if (!mounted) return;
      setState(() => _isLoadingImage = false);
    }
  }

  Future<Uint8List> _mockSamServer(double x, double y) async {
    await Future.delayed(const Duration(milliseconds: 700));
    if (_testImage == null) return Uint8List(0);

    final int imgW = _testImage!.width;
    final int imgH = _testImage!.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // خلفية سوداء (للوضوح) + دائرة بيضاء = ماسك
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imgW.toDouble(), imgH.toDouble()),
      Paint()..color = Colors.black,
    );

    canvas.drawCircle(
      Offset(x, y),
      90.0,
      Paint()..color = Colors.white,
    );

    final picture = recorder.endRecording();
    final img = await picture.toImage(imgW, imgH);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0F14),
      appBar: AppBar(
        title: Text('Test Auto Select (SAM)'),
        actions: [
          IconButton(
            onPressed: _loadSampleImage,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: Center(
        child: _isLoadingImage
            ? const CircularProgressIndicator()
            : _testImage == null
            ? Text('فشل تحميل الصورة', style: TextStyle(color: Colors.white))
            : Padding(
          padding: EdgeInsets.all(16.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: _testImage!.width / _testImage!.height,
              child: AutoMaskCanvas(
                image: _testImage!,
                onAutoSelect: _mockSamServer,
                overlayOpacity: 0.45,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =========================================================
// 2) Canvas: يعرض الصورة + يرسل Tap للإحداثيات الحقيقية + يعرض ماسك overlay
// =========================================================
class AutoMaskCanvas extends StatefulWidget {
  final ui.Image image;

  /// تتلقى (x,y) بإحداثيات الصورة الحقيقية (pixel coordinates)
  final Future<Uint8List> Function(double x, double y) onAutoSelect;

  final double overlayOpacity;

  const AutoMaskCanvas({
    super.key,
    required this.image,
    required this.onAutoSelect,
    this.overlayOpacity = 0.5,
  });

  @override
  State<AutoMaskCanvas> createState() => _AutoMaskCanvasState();
}

class _AutoMaskCanvasState extends State<AutoMaskCanvas> {
  bool _isLoading = false;
  Uint8List? _generatedMaskBytes;

  Offset _getRealImageCoordinates(Offset localPosition, Size widgetSize) {
    final double imgW = widget.image.width.toDouble();
    final double imgH = widget.image.height.toDouble();

    final double scaleX = imgW / widgetSize.width;
    final double scaleY = imgH / widgetSize.height;

    final double realX = localPosition.dx * scaleX;
    final double realY = localPosition.dy * scaleY;

    // clamp to bounds (احتياط)
    final dx = realX.clamp(0.0, imgW - 1);
    final dy = realY.clamp(0.0, imgH - 1);

    return Offset(dx, dy);
  }

  Future<void> _handleTap(TapDownDetails details, Size size) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final realCoords = _getRealImageCoordinates(details.localPosition, size);
      debugPrint('👆 Tap → real coords: X=${realCoords.dx}, Y=${realCoords.dy}');

      final maskBytes = await widget.onAutoSelect(realCoords.dx, realCoords.dy);

      if (!mounted) return;
      setState(() => _generatedMaskBytes = maskBytes);
    } catch (e) {
      debugPrint('🚨 Auto select failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapDown: (details) => _handleTap(details, size),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CustomPaint(painter: _ImagePainter(widget.image)),
              if (_generatedMaskBytes != null)
                Opacity(
                  opacity: widget.overlayOpacity,
                  child: Image.memory(
                    _generatedMaskBytes!,
                    fit: BoxFit.fill,
                    color: Colors.red, // لون overlay (اختياري)
                  ),
                ),
              if (_isLoading)
                Center(
                  child: CircularProgressIndicator(color: Colors.purpleAccent),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ImagePainter extends CustomPainter {
  final ui.Image image;
  _ImagePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.high,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// =========================================================
// 3) صفحة اختبار التكامل (SAM + LaMa) - Mock
//    - توليد ماسك عند النقر
//    - زر تنفيذ يظهر فقط عند وجود ماسك
// =========================================================
class ServerTestPage extends StatefulWidget {
  const ServerTestPage({super.key});

  @override
  State<ServerTestPage> createState() => _ServerTestPageState();
}

class _ServerTestPageState extends State<ServerTestPage> {
  ui.Image? _currentImage;
  Uint8List? _rawImageBytes;
  Uint8List? _lastGeneratedMask;

  bool _isProcessing = false;
  String _statusMessage = '';

  // ضع رابط سيرفرك الحقيقي لاحقًا
  final String serverUrl = "https://your-server-url.ngrok-free.app";

  @override
  void initState() {
    super.initState();
    _loadInitialImage();
  }

  Future<void> _loadInitialImage() async {
    setState(() {
      _statusMessage = "جاري تحميل الصورة...";
      _lastGeneratedMask = null;
      _isProcessing = false;
    });

    try {
      final response = await http
          .get(Uri.parse('https://picsum.photos/800/600'))
          .timeout(const Duration(seconds: 10));
      final bytes = response.bodyBytes;

      if (!mounted) return;
      _rawImageBytes = bytes;

      final codec = await ui.instantiateImageCodec(_rawImageBytes!);
      final frame = await codec.getNextFrame();

      if (!mounted) return;
      setState(() {
        _currentImage = frame.image;
        _statusMessage = "انقر على عنصر لتوليد ماسك، ثم نفّذ المسح";
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMessage = "فشل تحميل الصورة: $e");
    }
  }

  Future<Uint8List> _handleAutoSelect(double x, double y) async {
    setState(() => _statusMessage = "جاري تحديد العنصر (Mock SAM)...");

    // TODO: استبدل هذا بـ http.post لسيرفر SAM:
    // final mask = await _samRequest(imageBytes: _rawImageBytes!, x: x, y: y);

    final mask = await _mockSamServerResponse(x, y);

    if (!mounted) return mask;
    setState(() {
      _lastGeneratedMask = mask;
      _statusMessage = "تم التحديد ✅ الآن اضغط تنفيذ المسح";
    });

    return mask;
  }

  Future<void> _processInpainting() async {
    if (_rawImageBytes == null || _lastGeneratedMask == null) return;

    setState(() {
      _isProcessing = true;
      _statusMessage = "جاري المسح بالذكاء الاصطناعي (Mock LaMa)...";
    });

    try {
      // TODO: استبدل هذا بنداء LaMa الحقيقي:
      // 1) submit job
      // 2) poll result
      // 3) update image bytes

      await Future.delayed(const Duration(seconds: 2));

      // هنا (Mock) نفترض نجحت العملية
      setState(() {
        _lastGeneratedMask = null; // اخفاء التحديد بعد النجاح
        _statusMessage = "تم المسح بنجاح ✅ يمكنك تحديد عنصر آخر";
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ اكتملت المعالجة بنجاح")),
      );
    } catch (e) {
      setState(() => _statusMessage = "🚨 خطأ: $e");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<Uint8List> _mockSamServerResponse(double x, double y) async {
    await Future.delayed(const Duration(milliseconds: 700));

    if (_currentImage == null) return Uint8List(0);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final w = _currentImage!.width;
    final h = _currentImage!.height;

    // خلفية سوداء + دائرة بيضاء
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(x, y),
      75,
      Paint()..color = Colors.white,
    );

    final img = await recorder.endRecording().toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    final canRun = (_lastGeneratedMask != null && !_isProcessing);

    return Scaffold(
      backgroundColor: const Color(0xFF0F1720),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text("Server Integration Test"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isProcessing ? null : _loadInitialImage,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Center(
                  child: _currentImage == null
                      ? const CircularProgressIndicator(color: Color(0xFF2EE59D))
                      : Padding(
                    padding: EdgeInsets.all(16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: AspectRatio(
                        aspectRatio: _currentImage!.width / _currentImage!.height,
                        child: AutoMaskCanvas(
                          image: _currentImage!,
                          onAutoSelect: _handleAutoSelect,
                          overlayOpacity: 0.45,
                        ),
                      ),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black.withValues(alpha: 0.7),
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
            decoration: const BoxDecoration(
              color: Color(0xFF161D27),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 14),
                ),
                SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2EE59D),
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: canRun ? _processInpainting : null,
                        icon: Icon(Icons.auto_fix_high),
                        label: Text(
                          "تنفيذ المسح السحري",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  "serverUrl (لاحقًا): $serverUrl",
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}