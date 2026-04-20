import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/clean_edges/clean_edges_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_processing_flow.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_home_pick_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_operations_page.dart';

enum SharedToolMode { healRegion, cleanEdges }

class SharedHealCleanPage extends StatefulWidget {
  final SharedToolMode initialMode;

  const SharedHealCleanPage({
    super.key,
    required this.initialMode,
  });

  @override
  State<SharedHealCleanPage> createState() => _SharedHealCleanPageState();
}

class _SharedHealCleanPageState extends State<SharedHealCleanPage> {
  late SharedToolMode _activeMode;

  ui.Image? _decodedUiImage;
  Uint8List? _resultBytes;
  Uint8List? _originalBytesForResult;

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
    _activeMode = widget.initialMode;
    final healState = context.read<HealRegionCubit>().state;
    final cleanState = context.read<CleanEdgesCubit>().state;

    if (healState is HealRegionReady) {
      _decodeImage(healState.imageBytes);
    } else if (cleanState is CleanEdgesReady) {
      _decodeImage(cleanState.imageBytes);
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
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      await _decodeImage(bytes);
      if (context.mounted) {
        setState(() {
          _strokes.clear();
          _lensPosition = null;
          _resultBytes = null;
          _originalBytesForResult = null;
        });
        context.read<HealRegionCubit>().setImage(bytes);
        context.read<CleanEdgesCubit>().setImage(bytes);
      }
    }
  }

  Uint8List? _currentImageBytes(
      HealRegionState healState, CleanEdgesState cleanState) {
    if (_activeMode == SharedToolMode.healRegion &&
        healState is HealRegionReady) {
      return healState.imageBytes;
    }
    if (_activeMode == SharedToolMode.cleanEdges &&
        cleanState is CleanEdgesReady) {
      return cleanState.imageBytes;
    }
    return null;
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
    if (rawBytes == null) return null;
    if (_brushSoftness <= 0) return rawBytes;

    final decoded = img.decodePng(rawBytes);
    if (decoded == null) return rawBytes;
    final blurred =
        img.gaussianBlur(decoded, radius: _brushSoftness.clamp(1, 12).round());
    return Uint8List.fromList(img.encodePng(blurred));
  }

  Future<void> _submitHealRegion(
    BuildContext context,
    BoxConstraints constraints,
  ) async {
    if (_decodedUiImage == null || _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please mask an area to heal first!'),
        backgroundColor: Colors.orange,
      ));
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
      final healCubit = context.read<HealRegionCubit>();
      final currentImage = (healCubit.state as HealRegionReady).imageBytes;
      final localJobId = await healCubit.submitJob(maskBytes);
      if (!context.mounted || localJobId == null) {
        return;
      }

      setState(() {
        _strokes.clear();
        _resultBytes = null;
        _originalBytesForResult = currentImage;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HealProcessingFlow(
            originalBytes: currentImage,
            healCubit: healCubit,
          ),
        ),
      );
    }
  }

  Future<void> _submitCleanEdges(
    BuildContext context,
    BoxConstraints constraints,
  ) async {
    if (_decodedUiImage == null || _strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please mask an edge to clean first!'),
        backgroundColor: Colors.orange,
      ));
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
      final cleanCubit = context.read<CleanEdgesCubit>();
      final currentImage = (cleanCubit.state as CleanEdgesReady).imageBytes;
      final localJobId = await cleanCubit.submitJob(maskBytes);
      if (!context.mounted || localJobId == null) {
        return;
      }

      setState(() {
        _strokes.clear();
        _resultBytes = null;
        _originalBytesForResult = currentImage;
      });

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RemoteLamaOperationsPage(
            focusJobId: localJobId,
            resultTitle: 'Clean Edges Result',
            originalBytes: _originalBytesForResult,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<HealRegionCubit, HealRegionState>(
          listener: (context, state) {
            if (activeMode != SharedToolMode.healRegion) return;
            if (state is HealRegionFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                action: state.isRetryable
                    ? SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {})
                    : null,
              ));
            } else if (state is HealRegionSuccess) {
              _applyNewResult(state.resultBytes);
            }
          },
        ),
        BlocListener<CleanEdgesCubit, CleanEdgesState>(
          listener: (context, state) {
            if (activeMode != SharedToolMode.cleanEdges) return;
            if (state is CleanEdgesFailure) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
                action: state.isRetryable
                    ? SnackBarAction(
                        label: 'Dismiss',
                        textColor: Colors.white,
                        onPressed: () {})
                    : null,
              ));
            } else if (state is CleanEdgesSuccess) {
              _applyNewResult(state.resultBytes);
            }
          },
        ),
      ],
      child: BlocBuilder<HealRegionCubit, HealRegionState>(
        builder: (context, healState) {
          return BlocBuilder<CleanEdgesCubit, CleanEdgesState>(
            builder: (context, cleanState) {
              return Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/editor'),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeToggle(),
                    ],
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemoteLamaOperationsPage(),
                        ),
                      ),
                      icon: const Icon(Icons.dashboard_customize_rounded),
                    ),
                  ],
                ),
                body: Stack(
                  children: [
                    Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                            child: _buildMainContent(
                                context, healState, cleanState)),
                        if (_resultBytes == null &&
                            ((_activeMode == SharedToolMode.healRegion &&
                                    healState is HealRegionReady) ||
                                (_activeMode == SharedToolMode.cleanEdges &&
                                    cleanState is CleanEdgesReady)))
                          _buildToolbar(context, healState, cleanState),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  SharedToolMode get activeMode => _activeMode;

  void _applyNewResult(Uint8List newResultBytes) {
    final previousOriginal = _originalBytesForResult;
    setState(() {
      _strokes.clear();
      _resultBytes = newResultBytes;
      _originalBytesForResult ??= previousOriginal;
    });
    _decodeImage(newResultBytes);
    // Propagate image changes to both cubits
    context.read<HealRegionCubit>().setImage(newResultBytes);
    context.read<CleanEdgesCubit>().setImage(newResultBytes);
  }

  void _closeResultView() {
    setState(() {
      _resultBytes = null;
      _originalBytesForResult = null;
      _strokes.clear();
      _lensPosition = null;
    });
  }

  Widget _buildModeToggle() {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: LamaTheme.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(SharedToolMode.healRegion, 'Heal Region'),
          _buildToggleItem(SharedToolMode.cleanEdges, 'Clean Edges'),
        ],
      ),
    );
  }

  Widget _buildToggleItem(SharedToolMode mode, String label) {
    final isActive = _activeMode == mode;
    return GestureDetector(
      onTap: () {
        if (!isActive) {
          setState(() {
            _activeMode = mode;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? LamaTheme.accent.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive ? LamaTheme.accent : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? LamaTheme.accent : Colors.white54,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final text = _activeMode == SharedToolMode.healRegion
        ? 'Small targeted heals for blemishes. Use the brush to mask the area to repair.'
        : 'Remove halos and jagged borders around a mask. Use brush along edges.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: LamaTheme.toolbarBg.withValues(alpha: 0.5),
      child: Text(text,
          style: const TextStyle(color: Colors.white70, fontSize: 13)),
    );
  }

  Widget _buildMainContent(BuildContext context, HealRegionState healState,
      CleanEdgesState cleanState) {
    if (_resultBytes != null) {
      return LamaResultViewer(
        resultBytes: _resultBytes!,
        originalBytes: _originalBytesForResult,
        onReset: _closeResultView,
        onRetry: _closeResultView,
      );
    }

    final bool isReady = (_activeMode == SharedToolMode.healRegion &&
            healState is HealRegionReady) ||
        (_activeMode == SharedToolMode.cleanEdges &&
            cleanState is CleanEdgesReady);
    if (isReady && _decodedUiImage != null) {
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
                    child: _InteractiveSharedCanvas(
                      imageBytes: _currentImageBytes(healState, cleanState)!,
                      strokes: _strokes,
                      brushSize: _brushSize,
                      softness: _brushSoftness,
                      lensPosition: _lensPosition,
                      showLens: _activeMode == SharedToolMode.healRegion
                          ? _showLens
                          : false,
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
                  heroTag: 'processBtnShared',
                  backgroundColor: LamaTheme.accent,
                  onPressed: () {
                    if (_activeMode == SharedToolMode.healRegion) {
                      _submitHealRegion(context, constraints);
                    } else {
                      _submitCleanEdges(context, constraints);
                    }
                  },
                  icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                  label: Text(
                      _activeMode == SharedToolMode.healRegion
                          ? 'Apply Heal'
                          : 'Clean Edges',
                      style: const TextStyle(
                          color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      );
    }

    // fallback when not ready
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: LamaHomePickView(
          title: _activeMode == SharedToolMode.healRegion
              ? 'AI Heal Region'
              : 'AI Clean Edges',
          hint: _activeMode == SharedToolMode.healRegion
              ? 'Select an image to repair areas or remove blemishes.'
              : 'Select an image to clean up rough or jagged edges.',
          features: _activeMode == SharedToolMode.healRegion
              ? 'Smart Repair • Custom Brush • High Res'
              : 'Smooth Boundaries • Edge Fix • Studio Quality',
          onPickGallery: () => _pickImage(context, ImageSource.gallery),
          onPickCamera: () => _pickImage(context, ImageSource.camera),
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, HealRegionState healState,
      CleanEdgesState cleanState) {
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
            if (_activeMode == SharedToolMode.healRegion &&
                healState is HealRegionReady) ...[
              Row(
                children: [
                  const Text('Heal Radius: ',
                      style: TextStyle(color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: healState.healRadius.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      activeColor: Colors.blueAccent,
                      label: healState.healRadius.toString(),
                      onChanged: (v) => context
                          .read<HealRegionCubit>()
                          .updateRadius(v.toInt()),
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
            ] else if (_activeMode == SharedToolMode.cleanEdges &&
                cleanState is CleanEdgesReady) ...[
              Row(
                children: [
                  const Text('Edge Radius: ',
                      style: TextStyle(color: Colors.white70)),
                  Expanded(
                    child: Slider(
                      value: cleanState.edgeRadius.toDouble(),
                      min: 1,
                      max: 10,
                      divisions: 9,
                      activeColor: Colors.blueAccent,
                      label: cleanState.edgeRadius.toString(),
                      onChanged: (v) => context
                          .read<CleanEdgesCubit>()
                          .updateRadius(v.toInt()),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InteractiveSharedCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final double softness;
  final Offset? lensPosition;
  final bool showLens;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _InteractiveSharedCanvas({
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
                          'Draw over the area/edges you want to edit. Results preview here immediately.',
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
                      child: Icon(Icons.add, color: Colors.white, size: 18)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
