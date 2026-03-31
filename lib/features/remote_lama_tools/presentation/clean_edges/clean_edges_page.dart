import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/clean_edges/clean_edges_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class CleanEdgesPage extends StatefulWidget {
  const CleanEdgesPage({super.key});

  @override
  State<CleanEdgesPage> createState() => _CleanEdgesPageState();
}

class _CleanEdgesPageState extends State<CleanEdgesPage> {
  ui.Image? _decodedUiImage;
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  double _brushSize = 20.0;

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
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      await _decodeImage(bytes);
      if (context.mounted) {
        context.read<CleanEdgesCubit>().setImage(bytes);
        _strokes.clear();
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
        Paint()..color = Colors.black);

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

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
    return byteData?.buffer.asUint8List();
  }

  void _submit(BuildContext context, BoxConstraints constraints) async {
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please mask an edge to clean first!'),
          backgroundColor: Colors.orange));
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
      context.read<CleanEdgesCubit>().submitJob(maskBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CleanEdgesCubit, CleanEdgesState>(
      listener: (context, state) {
        if (state is CleanEdgesFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.redAccent,
            action: state.isRetryable
                ? SnackBarAction(
                    label: 'Dismiss', textColor: Colors.white, onPressed: () {})
                : null,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: LamaTheme.background,
          appBar: AppBar(
            backgroundColor: LamaTheme.toolbarBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/editor'),
            ),
            title: const Text('Clean Edges',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMainContent(context, state)),
                  if (state is CleanEdgesReady) _buildToolbar(context, state),
                ],
              ),
              if (state is CleanEdgesSubmitting ||
                  state is CleanEdgesProcessing)
                LamaStatusIndicator(
                  progress:
                      state is CleanEdgesProcessing ? state.status.progress : 0,
                  message: state is CleanEdgesProcessing
                      ? state.status.message
                      : 'Uploading...',
                  isProcessing: state is CleanEdgesProcessing,
                )
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
          'Remove halos and jagged borders around a mask. Use brush along edges.',
          style: TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }

  Widget _buildMainContent(BuildContext context, CleanEdgesState state) {
    if (state is CleanEdgesSuccess) {
      return LamaResultViewer(
        resultBytes: state.resultBytes,
        onReset: () {
          _strokes.clear();
          context.read<CleanEdgesCubit>().reset();
        },
      );
    }

    if (state is CleanEdgesInitial || state is CleanEdgesFailure) {
      return Center(
        child: ElevatedButton.icon(
          onPressed: () => _pickImage(context),
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Select Image'),
          style: ElevatedButton.styleFrom(
              backgroundColor: LamaTheme.accent,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
        ),
      );
    }

    if (state is CleanEdgesReady && _decodedUiImage != null) {
      return LayoutBuilder(builder: (context, constraints) {
        final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
        return Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(state.imageBytes, fit: BoxFit.contain),
                  GestureDetector(
                    onPanStart: (details) => setState(() =>
                        _strokes.add(_currentStroke = [details.localPosition])),
                    onPanUpdate: (details) => setState(
                        () => _currentStroke.add(details.localPosition)),
                    child: CustomPaint(
                        painter: LamaMaskPainter(
                            strokes: _strokes, brushSize: _brushSize)),
                  ),
                ],
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
                label: const Text('Clean Edges',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        );
      });
    }
    return const SizedBox.shrink();
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
                const Text('Edge Radius: ',
                    style: TextStyle(color: Colors.white70)),
                Expanded(
                  child: Slider(
                    value: state.edgeRadius.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: Colors.blueAccent,
                    label: state.edgeRadius.toString(),
                    onChanged: (v) =>
                        context.read<CleanEdgesCubit>().updateRadius(v.toInt()),
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
