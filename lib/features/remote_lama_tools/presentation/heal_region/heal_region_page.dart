import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class HealRegionPage extends StatefulWidget {
  const HealRegionPage({super.key});

  @override
  State<HealRegionPage> createState() => _HealRegionPageState();
}

class _HealRegionPageState extends State<HealRegionPage> {
  ui.Image? _decodedUiImage;
  Uint8List? _sourceBytes;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;
  Offset? _lensPosition;
  double _brushSize = 20;
  double _brushSoftness = 0;
  bool _showLens = true;

  @override
  void initState() {
    super.initState();
    final state = context.read<HealRegionCubit>().state;
    if (state is HealRegionReady) {
      _sourceBytes = state.imageBytes;
      _decodeImage(state.imageBytes);
    }
  }

  @override
  void dispose() {
    _decodedUiImage?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      await _decodeImage(bytes);
      if (context.mounted) {
        setState(() {
          _sourceBytes = bytes;
          _strokes.clear();
          _lensPosition = null;
        });
        context.read<HealRegionCubit>().setImage(bytes);
      }
    }
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _decodedUiImage?.dispose();
      _decodedUiImage = frame.image;
    });
  }

  bool _isInsideCanvas(Offset point, Size size) {
    return point.dx >= 0 &&
        point.dy >= 0 &&
        point.dx <= size.width &&
        point.dy <= size.height;
  }

  void _handlePointerDown(PointerDownEvent event, Size size) {
    if (!_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _lensPosition = event.localPosition;
      _currentStroke = <Offset>[event.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (_currentStroke == null || !_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _lensPosition = event.localPosition;
      _currentStroke!.add(event.localPosition);
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    setState(() {
      _currentStroke = null;
      _lensPosition = null;
    });
  }

  Future<Uint8List?> _generateMaskPng(Size widgetSize) async {
    if (_decodedUiImage == null || _strokes.isEmpty) return null;
    final int imgWidth = _decodedUiImage!.width;
    final int imgHeight = _decodedUiImage!.height;
    final double scaleX = imgWidth / widgetSize.width;
    final double scaleY = imgHeight / widgetSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, imgWidth.toDouble(), imgHeight.toDouble()),
      Paint()..color = Colors.black,
    );

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..maskFilter = _brushSoftness > 0
          ? MaskFilter.blur(
              BlurStyle.normal, _brushSoftness * ((scaleX + scaleY) / 2))
          : null;

    for (final points in _strokes) {
      if (points.isEmpty) continue;
      final path = Path()
        ..moveTo(points.first.dx * scaleX, points.first.dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      strokePaint.strokeWidth = _brushSize * ((scaleX + scaleY) / 2);
      canvas.drawPath(path, strokePaint);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(imgWidth, imgHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final rawBytes = byteData?.buffer.asUint8List();
    if (rawBytes == null) {
      return null;
    }
    if (_brushSoftness <= 0) {
      return rawBytes;
    }

    final decoded = img.decodePng(rawBytes);
    if (decoded == null) {
      return rawBytes;
    }
    final blurred =
        img.gaussianBlur(decoded, radius: _brushSoftness.clamp(1, 12).round());
    return Uint8List.fromList(img.encodePng(blurred));
  }

  void _submit(BuildContext context, BoxConstraints constraints) async {
    if (_decodedUiImage == null || _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please mask an area to heal first!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
    double w = constraints.maxWidth;
    double h = w / aspect;
    if (h > constraints.maxHeight) {
      h = constraints.maxHeight;
      w = h * aspect;
    }

    final maskBytes = await _generateMaskPng(Size(w, h));
    if (maskBytes != null && context.mounted) {
      context.read<HealRegionCubit>().submitJob(maskBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<HealRegionCubit, HealRegionState>(
      listener: (context, state) {
        if (state is HealRegionFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              action: state.isRetryable
                  ? SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.white,
                      onPressed: () {})
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: LamaTheme.background,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/editor'),
            ),
            title: const Text('Heal Region',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: LamaTheme.toolbarBg,
            elevation: 0,
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMainContent(context, state)),
                  if (state is HealRegionReady) _buildToolbar(context, state),
                ],
              ),
              if (state is HealRegionSubmitting ||
                  state is HealRegionProcessing)
                LamaStatusIndicator(
                  progress:
                      state is HealRegionProcessing ? state.status.progress : 0,
                  message: state is HealRegionProcessing
                      ? state.status.message
                      : 'Uploading...',
                  isProcessing: state is HealRegionProcessing,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: LamaTheme.toolbarBg.withValues(alpha: 0.5),
      child: const Text(
        'Small targeted heals for blemishes. Use the brush to mask the area to repair.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, HealRegionState state) {
    if (state is HealRegionSuccess) {
      return LamaResultViewer(
        resultBytes: state.resultBytes,
        originalBytes: _sourceBytes,
        onReset: () {
          setState(() {
            _strokes.clear();
            _sourceBytes = null;
          });
          context.read<HealRegionCubit>().reset();
        },
      );
    }

    if (state is HealRegionInitial || state is HealRegionFailure) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => _pickImage(context),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Select Image'),
          style: ElevatedButton.styleFrom(
            backgroundColor: LamaTheme.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    if (state is HealRegionReady && _decodedUiImage != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
          return Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: aspect,
                child: _InteractiveHealCanvas(
                  imageBytes: state.imageBytes,
                  strokes: _strokes,
                  brushSize: _brushSize,
                  softness: _brushSoftness,
                  lensPosition: _lensPosition,
                  showLens: _showLens,
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerEnd: _handlePointerEnd,
                ),
              ),
              Positioned(
                bottom: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'processBtnHeal',
                  backgroundColor: LamaTheme.accent,
                  onPressed: () => _submit(context, constraints),
                  icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                  label: const Text('Apply Heal',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildToolbar(BuildContext context, HealRegionReady state) {
    return Container(
      color: LamaTheme.toolbarBg,
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.brush, color: Colors.white54, size: 20),
                Expanded(
                  child: Slider(
                    value: _brushSize,
                    min: 5,
                    max: 80,
                    activeColor: LamaTheme.accent,
                    label: _brushSize.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _brushSize = v),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white54),
                  onPressed: _strokes.isNotEmpty
                      ? () => setState(() => _strokes.removeLast())
                      : null,
                ),
              ],
            ),
            Row(
              children: [
                const Text('Heal Radius: ',
                    style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: state.healRadius.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: Colors.blueAccent,
                    label: state.healRadius.toString(),
                    onChanged: (v) =>
                        context.read<HealRegionCubit>().updateRadius(v.toInt()),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text('Feather / Softness: ',
                    style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: _brushSoftness,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    activeColor: Colors.orangeAccent,
                    label: _brushSoftness.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _brushSoftness = v),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.search, color: Colors.white54, size: 18),
                const SizedBox(width: 8),
                const Text('Lens', style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Switch.adaptive(
                  value: _showLens,
                  activeColor: LamaTheme.accent,
                  onChanged: (value) => setState(() => _showLens = value),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveHealCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final Offset? lensPosition;
  final bool showLens;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _InteractiveHealCanvas({
    required this.imageBytes,
    required this.strokes,
    required this.brushSize,
    required this.softness,
    required this.lensPosition,
    required this.showLens,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white12),
            color: Colors.black.withValues(alpha: 0.18),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(imageBytes, fit: BoxFit.contain),
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => onPointerDown(event, size),
                  onPointerMove: (event) => onPointerMove(event, size),
                  onPointerUp: onPointerEnd,
                  onPointerCancel: onPointerEnd,
                  child: Container(
                    color: Colors.transparent,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: LamaMaskPainter(
                          strokes: strokes,
                          brushSize: brushSize,
                          softness: softness,
                          color: const Color(0x99FF7A59),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Text(
                          'Softness feathers the mask edge locally before sending it to the heal API.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showLens && lensPosition != null)
                  _HealLens(
                    imageBytes: imageBytes,
                    strokes: strokes,
                    brushSize: brushSize,
                    softness: softness,
                    focus: lensPosition!,
                    canvasSize: size,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _HealLens extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final Offset focus;
  final Size canvasSize;

  const _HealLens({
    required this.imageBytes,
    required this.strokes,
    required this.brushSize,
    required this.softness,
    required this.focus,
    required this.canvasSize,
  });

  @override
  Widget build(BuildContext context) {
    const diameter = 120.0;
    const zoom = 2.2;
    final left = (focus.dx + 18).clamp(8.0, canvasSize.width - diameter - 8);
    final top =
        (focus.dy - diameter - 18).clamp(8.0, canvasSize.height - diameter - 8);
    final offsetX = -(focus.dx * zoom) + (diameter / 2);
    final offsetY = -(focus.dy * zoom) + (diameter / 2);

    return Positioned(
      left: left,
      top: top,
      child: IgnorePointer(
        child: Container(
          width: diameter,
          height: diameter,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipOval(
            child: ColoredBox(
              color: Colors.black,
              child: Stack(
                children: [
                  Transform.translate(
                    offset: Offset(offsetX, offsetY),
                    child: Transform.scale(
                      alignment: Alignment.topLeft,
                      scale: zoom,
                      child: SizedBox(
                        width: canvasSize.width,
                        height: canvasSize.height,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.memory(imageBytes, fit: BoxFit.contain),
                            CustomPaint(
                              painter: LamaMaskPainter(
                                strokes: strokes,
                                brushSize: brushSize,
                                softness: softness,
                                color: const Color(0xCCFF8B6E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const Center(
                    child: Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
