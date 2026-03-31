import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/repair_mask_assist_cubit.dart';

class RepairDamagePage extends StatefulWidget {
  const RepairDamagePage({super.key});

  @override
  State<RepairDamagePage> createState() => _RepairDamagePageState();
}

class _RepairDamagePageState extends State<RepairDamagePage> {
  ui.Image? _decodedUiImage;
  Uint8List? _sourceBytes;
  final List<List<Offset>> _manualStrokes = <List<Offset>>[];
  List<Offset>? _manualCurrentStroke;
  List<Offset>? _assistCurrentStroke;
  double _manualBrushSize = 20;
  double _assistBrushSize = 28;

  @override
  void initState() {
    super.initState();
    final state = context.read<RepairDamageCubit>().state;
    if (state is RepairDamageReady) {
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
          _manualStrokes.clear();
          _manualCurrentStroke = null;
          _assistCurrentStroke = null;
        });
        context.read<RepairDamageCubit>().setImage(bytes);
        await context
            .read<RepairMaskAssistCubit>()
            .setImage(bytes, resetMode: false);
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

  void _handleManualPointerDown(PointerDownEvent event, Size size) {
    if (!_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _manualCurrentStroke = <Offset>[event.localPosition];
      _manualStrokes.add(_manualCurrentStroke!);
    });
  }

  void _handleManualPointerMove(PointerMoveEvent event, Size size) {
    if (_manualCurrentStroke == null ||
        !_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _manualCurrentStroke!.add(event.localPosition);
    });
  }

  void _handleManualPointerEnd(PointerEvent event) {
    _manualCurrentStroke = null;
  }

  void _handleAssistPointerDown(PointerDownEvent event, Size size) {
    if (!_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _assistCurrentStroke = <Offset>[event.localPosition];
    });
  }

  Future<void> _handleAssistPointerMove(
      PointerMoveEvent event, Size size) async {
    if (_assistCurrentStroke == null ||
        !_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _assistCurrentStroke!.add(event.localPosition);
    });
  }

  Future<void> _handleAssistPointerEnd(PointerEvent event, Size size) async {
    final currentStroke = _assistCurrentStroke;
    if (currentStroke == null || currentStroke.isEmpty) {
      _assistCurrentStroke = null;
      return;
    }

    final assistCubit = context.read<RepairMaskAssistCubit>();
    final assistState = assistCubit.state;
    if (!assistState.hasSuggestion) {
      setState(() {
        _assistCurrentStroke = null;
      });
      return;
    }

    final imagePoints = _toImageSpace(
      currentStroke,
      size: size,
      imageWidth: assistState.maskWidth,
      imageHeight: assistState.maskHeight,
    );

    setState(() {
      _assistCurrentStroke = null;
    });

    await assistCubit.commitStroke(
      imagePoints: imagePoints,
      brushRadius: _assistBrushSize,
    );
  }

  List<Offset> _toImageSpace(
    List<Offset> widgetPoints, {
    required Size size,
    required int imageWidth,
    required int imageHeight,
  }) {
    final scaleX = imageWidth / size.width;
    final scaleY = imageHeight / size.height;
    return widgetPoints
        .map((point) => Offset(point.dx * scaleX, point.dy * scaleY))
        .toList(growable: false);
  }

  Future<Uint8List?> _generateManualMaskPng(Size widgetSize) async {
    if (_decodedUiImage == null || _manualStrokes.isEmpty) return null;
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
      ..style = PaintingStyle.stroke;

    for (final points in _manualStrokes) {
      if (points.isEmpty) continue;
      final path = Path()
        ..moveTo(points.first.dx * scaleX, points.first.dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      strokePaint.strokeWidth = _manualBrushSize * ((scaleX + scaleY) / 2);
      canvas.drawPath(path, strokePaint);
    }
    final picture = recorder.endRecording();
    final image = await picture.toImage(imgWidth, imgHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  Future<void> _submit(BuildContext context, BoxConstraints constraints) async {
    final assistState = context.read<RepairMaskAssistCubit>().state;

    if (assistState.creationMode == MaskCreationMode.manual) {
      if (_manualStrokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please mask the damaged area first!'),
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

      final maskBytes = await _generateManualMaskPng(Size(w, h));
      if (maskBytes != null && context.mounted) {
        context.read<RepairDamageCubit>().submitJob(maskBytes);
      }
      return;
    }

    if (!assistState.hasSuggestion) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Generate or refine an AI assist mask before applying repair.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final maskBytes =
        await context.read<RepairMaskAssistCubit>().exportMaskPng();
    if (maskBytes != null && context.mounted) {
      context.read<RepairDamageCubit>().submitJob(maskBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RepairDamageCubit, RepairDamageState>(
      listener: (context, state) {
        if (state is RepairDamageFailure) {
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
            backgroundColor: LamaTheme.toolbarBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/editor'),
            ),
            title: const Text('Repair Damage',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            actions: [
              IconButton(
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMainContent(context, state)),
                  if (state is RepairDamageReady) _buildToolbar(context, state),
                ],
              ),
              if (state is RepairDamageSubmitting ||
                  state is RepairDamageProcessing)
                LamaStatusIndicator(
                  progress: state is RepairDamageProcessing
                      ? state.status.progress
                      : 0,
                  message: state is RepairDamageProcessing
                      ? state.status.message
                      : 'Uploading...',
                  isProcessing: state is RepairDamageProcessing,
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
        'Deep structural repair for corrupted areas. Manual masking stays fully available, and AI Assist can generate an editable starting mask you can refine before applying repair.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, RepairDamageState state) {
    if (state is RepairDamageSuccess) {
      return LamaResultViewer(
        resultBytes: state.resultBytes,
        originalBytes: _sourceBytes,
        onReset: () {
          setState(() {
            _manualStrokes.clear();
            _manualCurrentStroke = null;
            _assistCurrentStroke = null;
            _sourceBytes = null;
          });
          context.read<RepairDamageCubit>().reset();
          context
              .read<RepairMaskAssistCubit>()
              .setCreationMode(MaskCreationMode.manual);
        },
      );
    }

    if (state is RepairDamageInitial || state is RepairDamageFailure) {
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

    if (state is RepairDamageReady && _decodedUiImage != null) {
      return BlocBuilder<RepairMaskAssistCubit, RepairMaskAssistState>(
        builder: (context, assistState) {
          final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
          return LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: _CreationModeSwitcher(
                      mode: assistState.creationMode,
                      onChanged: (mode) => context
                          .read<RepairMaskAssistCubit>()
                          .setCreationMode(mode),
                    ),
                  ),
                  Expanded(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: aspect,
                          child: assistState.creationMode ==
                                  MaskCreationMode.manual
                              ? _ManualRepairCanvas(
                                  imageBytes: state.imageBytes,
                                  strokes: _manualStrokes,
                                  currentStroke: _manualCurrentStroke,
                                  brushSize: _manualBrushSize,
                                  onPointerDown: _handleManualPointerDown,
                                  onPointerMove: _handleManualPointerMove,
                                  onPointerEnd: _handleManualPointerEnd,
                                )
                              : _AiRepairCanvas(
                                  imageBytes: state.imageBytes,
                                  previewPng: assistState.previewVisible
                                      ? assistState.maskPreviewPng
                                      : null,
                                  strokes: _assistCurrentStroke == null
                                      ? const <List<Offset>>[]
                                      : <List<Offset>>[_assistCurrentStroke!],
                                  brushSize: _assistBrushSize,
                                  editMode: assistState.editMode,
                                  onPointerDown: _handleAssistPointerDown,
                                  onPointerMove: _handleAssistPointerMove,
                                  onPointerEnd: (event, size) =>
                                      _handleAssistPointerEnd(event, size),
                                ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: FloatingActionButton.extended(
                            heroTag: 'processBtnRepair',
                            backgroundColor: LamaTheme.accent,
                            onPressed: () => _submit(context, constraints),
                            icon: const Icon(Icons.auto_fix_high,
                                color: Colors.black),
                            label: const Text('Apply Repair',
                                style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildToolbar(BuildContext context, RepairDamageReady state) {
    return BlocBuilder<RepairMaskAssistCubit, RepairMaskAssistState>(
      builder: (context, assistState) {
        if (assistState.creationMode == MaskCreationMode.manual) {
          return Container(
            color: LamaTheme.toolbarBg,
            padding: const EdgeInsets.all(16),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  const Icon(Icons.brush, color: Colors.white54, size: 20),
                  Expanded(
                    child: Slider(
                      value: _manualBrushSize,
                      min: 5,
                      max: 80,
                      activeColor: LamaTheme.accent,
                      onChanged: (v) => setState(() => _manualBrushSize = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white54),
                    onPressed: _manualStrokes.isNotEmpty
                        ? () => setState(() => _manualStrokes.removeLast())
                        : null,
                  ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: LamaTheme.toolbarBg,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: assistState.generationStatus ==
                                MaskGenerationStatus.generating
                            ? null
                            : () => context
                                .read<RepairMaskAssistCubit>()
                                .generateSuggestion(),
                        icon: assistState.generationStatus ==
                                MaskGenerationStatus.generating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.black))
                            : const Icon(Icons.auto_awesome,
                                color: Colors.black),
                        label: const Text('Auto Detect',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: LamaTheme.accent),
                      ),
                      OutlinedButton.icon(
                        onPressed: assistState.sourceImageBytes == null
                            ? null
                            : () => context
                                .read<RepairMaskAssistCubit>()
                                .retrySuggestion(),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: assistState.canUndo
                            ? () => context.read<RepairMaskAssistCubit>().undo()
                            : null,
                        icon: const Icon(Icons.undo_rounded),
                        label: const Text('Undo'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: assistState.canRedo
                            ? () => context.read<RepairMaskAssistCubit>().redo()
                            : null,
                        icon: const Icon(Icons.redo_rounded),
                        label: const Text('Redo'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  if (assistState.errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(assistState.errorMessage!,
                        style: const TextStyle(
                            color: Colors.orangeAccent, fontSize: 12.5)),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Mask Edit:',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(width: 10),
                      _EditModeChip(
                        label: 'Add',
                        selected: assistState.editMode == MaskEditMode.add,
                        icon: Icons.add_rounded,
                        onTap: () => context
                            .read<RepairMaskAssistCubit>()
                            .setEditMode(MaskEditMode.add),
                      ),
                      const SizedBox(width: 8),
                      _EditModeChip(
                        label: 'Erase',
                        selected: assistState.editMode == MaskEditMode.erase,
                        icon: Icons.remove_rounded,
                        onTap: () => context
                            .read<RepairMaskAssistCubit>()
                            .setEditMode(MaskEditMode.erase),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Brush Radius',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Slider(
                          value: _assistBrushSize,
                          min: 8,
                          max: 110,
                          activeColor: LamaTheme.accent,
                          label: _assistBrushSize.round().toString(),
                          onChanged: (value) =>
                              setState(() => _assistBrushSize = value),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Feather',
                          style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Slider(
                          value: assistState.feather,
                          min: 0,
                          max: 12,
                          divisions: 12,
                          activeColor: Colors.orangeAccent,
                          label: assistState.feather.round().toString(),
                          onChanged: (value) => context
                              .read<RepairMaskAssistCubit>()
                              .updateFeather(value),
                        ),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: assistState.hasSuggestion
                            ? () => context
                                .read<RepairMaskAssistCubit>()
                                .transformMask(MaskTransformAction.expand)
                            : null,
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label: const Text('Expand Mask'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: assistState.hasSuggestion
                            ? () => context
                                .read<RepairMaskAssistCubit>()
                                .transformMask(MaskTransformAction.contract)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                        label: const Text('Contract Mask'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                      OutlinedButton.icon(
                        onPressed: assistState.hasSuggestion
                            ? () => context
                                .read<RepairMaskAssistCubit>()
                                .clearMask()
                            : null,
                        icon: const Icon(Icons.layers_clear_rounded),
                        label: const Text('Clear Mask'),
                        style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Preview Mask',
                          style: TextStyle(color: Colors.white70)),
                      const Spacer(),
                      Switch.adaptive(
                        value: assistState.previewVisible,
                        activeColor: LamaTheme.accent,
                        onChanged: (value) => context
                            .read<RepairMaskAssistCubit>()
                            .togglePreview(value),
                      ),
                    ],
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

class _CreationModeSwitcher extends StatelessWidget {
  final MaskCreationMode mode;
  final ValueChanged<MaskCreationMode> onChanged;

  const _CreationModeSwitcher({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<MaskCreationMode>(
      segments: const [
        ButtonSegment<MaskCreationMode>(
            value: MaskCreationMode.manual,
            label: Text('Manual'),
            icon: Icon(Icons.brush_rounded)),
        ButtonSegment<MaskCreationMode>(
            value: MaskCreationMode.aiAssist,
            label: Text('AI Assist'),
            icon: Icon(Icons.auto_awesome_rounded)),
      ],
      selected: <MaskCreationMode>{mode},
      onSelectionChanged: (selection) => onChanged(selection.first),
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return LamaTheme.accent.withValues(alpha: 0.18);
          }
          return Colors.white.withValues(alpha: 0.04);
        }),
        foregroundColor: WidgetStateProperty.all(Colors.white),
        side: WidgetStateProperty.all(const BorderSide(color: Colors.white12)),
      ),
    );
  }
}

class _EditModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _EditModeChip(
      {required this.label,
      required this.selected,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? LamaTheme.accent.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: selected ? LamaTheme.accent : Colors.white12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected ? LamaTheme.accent : Colors.white70, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: selected ? LamaTheme.accent : Colors.white70,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _ManualRepairCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final List<Offset>? currentStroke;
  final double brushSize;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _ManualRepairCanvas({
    required this.imageBytes,
    required this.strokes,
    required this.currentStroke,
    required this.brushSize,
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
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LamaMaskPainter(
                          strokes: strokes, brushSize: brushSize),
                      child: const SizedBox.expand(),
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

class _AiRepairCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final Uint8List? previewPng;
  final List<List<Offset>> strokes;
  final double brushSize;
  final MaskEditMode editMode;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event, Size size) onPointerEnd;

  const _AiRepairCanvas({
    required this.imageBytes,
    required this.previewPng,
    required this.strokes,
    required this.brushSize,
    required this.editMode,
    required this.onPointerDown,
    required this.onPointerMove,
    required this.onPointerEnd,
  });

  @override
  Widget build(BuildContext context) {
    final previewColor = editMode == MaskEditMode.add
        ? const Color(0xAA56E39F)
        : const Color(0xAFFF6B6B);
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
                if (previewPng != null)
                  Image.memory(previewPng!, fit: BoxFit.fill),
                Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (event) => onPointerDown(event, size),
                  onPointerMove: (event) => onPointerMove(event, size),
                  onPointerUp: (event) => onPointerEnd(event, size),
                  onPointerCancel: (event) => onPointerEnd(event, size),
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: LamaMaskPainter(
                        strokes: strokes,
                        brushSize: brushSize,
                        color: previewColor,
                      ),
                      child: const SizedBox.expand(),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(
                          editMode == MaskEditMode.add
                              ? 'AI Assist active. Paint to add more repair coverage.'
                              : 'AI Assist active. Paint to erase extra mask areas.',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
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
