import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_home_pick_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_processing_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/shared_heal_clean_page.dart';

class HealRegionPage extends StatefulWidget {
  const HealRegionPage({super.key});

  @override
  State<HealRegionPage> createState() => _HealRegionPageState();
}

class _HealRegionPageState extends State<HealRegionPage> {
  ui.Image? _decodedUiImage;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;
  Offset? _lensPosition;
  double _brushSize = 20;
  double _brushSoftness = 0;
  bool _showLens = true;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    final state = context.read<HealRegionCubit>().state;
    if (state is HealRegionReady) {
      _decodeImage(state.imageBytes);
    }
  }

  @override
  void dispose() {
    _decodedUiImage?.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: source);
    if (xfile == null) return;

    final bytes = await xfile.readAsBytes();
    await _decodeImage(bytes);
    if (!context.mounted) return;

    setState(() {
      _strokes.clear();
      _lensPosition = null;
    });
    context.read<HealRegionCubit>().setImage(bytes);
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
    if (!_isInsideCanvas(event.localPosition, size)) return;
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
              BlurStyle.normal,
              _brushSoftness * ((scaleX + scaleY) / 2),
            )
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
    if (rawBytes == null) return null;
    if (_brushSoftness <= 0) return rawBytes;

    final decoded = img.decodePng(rawBytes);
    if (decoded == null) return rawBytes;
    final blurred =
        img.gaussianBlur(decoded, radius: _brushSoftness.clamp(1, 12).round());
    return Uint8List.fromList(img.encodePng(blurred));
  }

  Future<void> _submit(BuildContext context, BoxConstraints constraints) async {
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
    double width = constraints.maxWidth;
    double height = width / aspect;
    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspect;
    }

    final maskBytes = await _generateMaskPng(Size(width, height));
    if (maskBytes == null || !context.mounted) return;

    final healCubit = context.read<HealRegionCubit>();
    final currentState = healCubit.state;
    if (currentState is! HealRegionReady) {
      return;
    }

    final localJobId = await healCubit.submitJob(maskBytes);
    if (localJobId == null || !context.mounted) {
      return;
    }
    final currentImage = currentState.imageBytes;
    setState(() {
      _strokes.clear();
    });

    final resultBytes = await Navigator.of(context).push<Uint8List>(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: healCubit,
          child: RemoteLamaProcessingPage(
            activeMode: SharedToolMode.healRegion,
            imageBytes: currentImage,
          ),
        ),
      ),
    );
    if (resultBytes != null && mounted) {
      _applyNewResult(resultBytes);
    }
  }

  void _applyNewResult(Uint8List newResultBytes) {
    _decodeImage(newResultBytes);
    setState(() {
      _strokes.clear();
    });
    context.read<HealRegionCubit>().setImage(newResultBytes);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<HealRegionCubit, HealRegionState>(
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
                      onPressed: () {},
                    )
                  : null,
            ),
          );
        } else if (state is HealRegionSuccess) {
          _applyNewResult(state.resultBytes);
        }
      },
      child: BlocBuilder<HealRegionCubit, HealRegionState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).maybePop(),
              ),
              title: const Text('AI Heal Region'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  color: LamaTheme.toolbarBg.withValues(alpha: 0.5),
                  child: const Text(
                    'Small targeted heals for blemishes. Use the brush to mask the area to repair.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Expanded(child: _buildMainContent(context, state)),
                if (state is HealRegionReady) _buildToolbar(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, HealRegionState state) {
    if (state is HealRegionReady && _decodedUiImage != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
          return Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                transformationController: _transformationController,
                panEnabled: true,
                scaleEnabled: true,
                maxScale: 5.0,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: aspect,
                    child: _HealCanvas(
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
                  label: const Text(
                    'Apply Heal',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: LamaHomePickView(
          title: 'AI Heal Region',
          hint: 'Select an image to repair areas or remove blemishes.',
          features: 'Smart Repair • Custom Brush • High Res',
          onPickGallery: () => _pickImage(context, ImageSource.gallery),
          onPickCamera: () => _pickImage(context, ImageSource.camera),
        ),
      ),
    );
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
                    onChanged: (value) => setState(() => _brushSize = value),
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
                const Text(
                  'Heal Radius: ',
                  style: TextStyle(color: Colors.white70),
                ),
                Expanded(
                  child: Slider(
                    value: state.healRadius.toDouble(),
                    min: 0,
                    max: 20,
                    divisions: 20,
                    activeColor: Colors.blueAccent,
                    label: state.healRadius.toString(),
                    onChanged: (value) => context
                        .read<HealRegionCubit>()
                        .updateRadius(value.toInt()),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                const Text(
                  'Feather / Softness: ',
                  style: TextStyle(color: Colors.white70),
                ),
                Expanded(
                  child: Slider(
                    value: _brushSoftness,
                    min: 0,
                    max: 12,
                    divisions: 12,
                    activeColor: Colors.orangeAccent,
                    label: _brushSoftness.toStringAsFixed(0),
                    onChanged: (value) =>
                        setState(() => _brushSoftness = value),
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

class _HealCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final Offset? lensPosition;
  final bool showLens;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _HealCanvas({
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
                  child: ColoredBox(
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
                          'Draw over the area you want to heal. Results preview here immediately.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
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
