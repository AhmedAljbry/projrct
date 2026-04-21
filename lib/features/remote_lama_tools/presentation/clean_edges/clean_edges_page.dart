import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/clean_edges/clean_edges_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_home_pick_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_processing_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/shared_heal_clean_page.dart';

class CleanEdgesPage extends StatefulWidget {
  const CleanEdgesPage({super.key});

  @override
  State<CleanEdgesPage> createState() => _CleanEdgesPageState();
}

class _CleanEdgesPageState extends State<CleanEdgesPage> {
  ui.Image? _decodedUiImage;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;
  double _brushSize = 20;
  double _brushSoftness = 0;
  final TransformationController _transformationController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CleanEdgesCubit>().state;
    if (state is CleanEdgesReady) {
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
    });
    context.read<CleanEdgesCubit>().setImage(bytes);
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
      _currentStroke = <Offset>[event.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (_currentStroke == null || !_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _currentStroke!.add(event.localPosition);
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    setState(() {
      _currentStroke = null;
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
          content: Text('Please mask an edge to clean first!'),
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

    final cleanCubit = context.read<CleanEdgesCubit>();
    final currentState = cleanCubit.state;
    if (currentState is! CleanEdgesReady) {
      return;
    }

    final originalBytes = currentState.imageBytes;
    final localJobId = await cleanCubit.submitJob(maskBytes);
    if (localJobId == null || !context.mounted) {
      return;
    }
    setState(() {
      _strokes.clear();
    });
    final resultBytes = await Navigator.push<Uint8List>(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: cleanCubit,
          child: RemoteLamaProcessingPage(
            activeMode: SharedToolMode.cleanEdges,
            imageBytes: originalBytes,
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
    context.read<CleanEdgesCubit>().setImage(newResultBytes);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CleanEdgesCubit, CleanEdgesState>(
      listener: (context, state) {
        if (state is CleanEdgesFailure) {
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
        } else if (state is CleanEdgesSuccess) {
          _applyNewResult(state.resultBytes);
        }
      },
      child: BlocBuilder<CleanEdgesCubit, CleanEdgesState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    Navigator.of(context, rootNavigator: true).maybePop(),
              ),
              title: const Text('AI Clean Edges'),
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
                    'Remove halos and jagged borders around a mask. Use brush along edges.',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Expanded(child: _buildMainContent(context, state)),
                if (state is CleanEdgesReady) _buildToolbar(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, CleanEdgesState state) {
    if (state is CleanEdgesReady && _decodedUiImage != null) {
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
                    child: _CleanEdgesCanvas(
                      imageBytes: state.imageBytes,
                      strokes: _strokes,
                      brushSize: _brushSize,
                      softness: _brushSoftness,
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
                  heroTag: 'processBtnClean',
                  backgroundColor: LamaTheme.accent,
                  onPressed: () => _submit(context, constraints),
                  icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                  label: const Text(
                    'Clean Edges',
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
          title: 'AI Clean Edges',
          hint: 'Select an image to clean up rough or jagged edges.',
          features: 'Smooth Boundaries • Edge Fix • Studio Quality',
          onPickGallery: () => _pickImage(context, ImageSource.gallery),
          onPickCamera: () => _pickImage(context, ImageSource.camera),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, CleanEdgesReady state) {
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
                  'Edge Radius: ',
                  style: TextStyle(color: Colors.white70),
                ),
                Expanded(
                  child: Slider(
                    value: state.edgeRadius.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: Colors.blueAccent,
                    label: state.edgeRadius.toString(),
                    onChanged: (value) => context
                        .read<CleanEdgesCubit>()
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
          ],
        ),
      ),
    );
  }
}

class _CleanEdgesCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _CleanEdgesCanvas({
    required this.imageBytes,
    required this.strokes,
    required this.brushSize,
    required this.softness,
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
                          'Brush only along rough borders and mask edges for a cleaner cutout.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
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
