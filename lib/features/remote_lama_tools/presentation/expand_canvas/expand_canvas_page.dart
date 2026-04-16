import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/expand_canvas/expand_canvas_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/expand/expand_mask_assist_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_home_pick_view.dart';

class ExpandCanvasPage extends StatefulWidget {
  const ExpandCanvasPage({super.key});

  @override
  State<ExpandCanvasPage> createState() => _ExpandCanvasPageState();
}

class _ExpandCanvasPageState extends State<ExpandCanvasPage> {
  ui.Image? _decodedUiImage;
  Uint8List? _sourceBytes;
  List<Offset>? _assistCurrentStroke;
  double _assistBrushSize = 24;

  @override
  void initState() {
    super.initState();
    final state = context.read<ExpandCanvasCubit>().state;
    if (state is ExpandCanvasReady) {
      _sourceBytes = state.imageBytes;
      _decodeImage(state.imageBytes);
    }
  }

  @override
  void dispose() {
    _decodedUiImage?.dispose();
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
          _sourceBytes = bytes;
          _assistCurrentStroke = null;
        });
        context.read<ExpandCanvasCubit>().setImage(bytes);
        await context.read<ExpandMaskAssistCubit>().setImage(bytes);
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

  void _handleAssistPointerDown(PointerDownEvent event, Size size) {
    if (!_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _assistCurrentStroke = <Offset>[event.localPosition];
    });
  }

  void _handleAssistPointerMove(PointerMoveEvent event, Size size) {
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

    final assistCubit = context.read<ExpandMaskAssistCubit>();
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

  Future<void> _submit(BuildContext context) async {
    final assistState = context.read<ExpandMaskAssistCubit>().state;
    Uint8List? maskBytes;

    if (assistState.creationMode == MaskCreationMode.aiAssist) {
      if (!assistState.hasSuggestion) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Generate or refine an AI guidance mask before applying guided expand.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      maskBytes = await context.read<ExpandMaskAssistCubit>().exportMaskPng();
    }

    if (context.mounted) {
      context.read<ExpandCanvasCubit>().submitJob(maskBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExpandCanvasCubit, ExpandCanvasState>(
      listener: (context, state) {
        if (state is ExpandCanvasFailure) {
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
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/editor'),
            ),
            title: const Text(
              'Expand Canvas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              IconButton(
                onPressed: () => _pickImage(context, ImageSource.gallery),
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
                  if (state is ExpandCanvasReady) _buildToolbar(context, state),
                ],
              ),
              if (state is ExpandCanvasSubmitting ||
                  state is ExpandCanvasProcessing)
                LamaStatusIndicator(
                  progress: state is ExpandCanvasProcessing
                      ? state.status.progress
                      : 0,
                  message: state is ExpandCanvasProcessing
                      ? state.status.message
                      : 'Uploading...',
                  isProcessing: state is ExpandCanvasProcessing,
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
        'Outpainting extends the frame around your image. Manual mode keeps the original expand workflow unchanged, while AI Assist can generate an editable guidance mask to better protect the main subject during expansion.',
        style: TextStyle(color: Colors.white70, fontSize: 13),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ExpandCanvasState state) {
    if (state is ExpandCanvasSuccess) {
      return LamaResultViewer(
        resultBytes: state.resultBytes,
        originalBytes: _sourceBytes,
        onReset: () {
          setState(() {
            _sourceBytes = null;
            _assistCurrentStroke = null;
          });
          context.read<ExpandCanvasCubit>().reset();
          context
              .read<ExpandMaskAssistCubit>()
              .setCreationMode(MaskCreationMode.manual);
        },
      );
    }

    if (state is ExpandCanvasInitial || state is ExpandCanvasFailure) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LamaHomePickView(
            title: 'AI Expand Canvas',
            hint: 'Select an image to easily extend its content and borders.',
            features: 'Smart Outpainting • Fast Render • High Fidelity',
            onPickGallery: () => _pickImage(context, ImageSource.gallery),
            onPickCamera: () => _pickImage(context, ImageSource.camera),
          ),
        ),
      );
    }

    if (state is ExpandCanvasReady && _decodedUiImage != null) {
      return BlocBuilder<ExpandMaskAssistCubit, ExpandMaskAssistState>(
        builder: (context, assistState) {
          final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    _CreationModeSwitcher(
                      mode: assistState.creationMode,
                      onChanged: (mode) => context
                          .read<ExpandMaskAssistCubit>()
                          .setCreationMode(mode),
                    ),
                    if (assistState.creationMode == MaskCreationMode.aiAssist)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: _AiAssistQuickActions(assistState: assistState),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AspectRatio(
                      aspectRatio: aspect,
                      child: assistState.creationMode == MaskCreationMode.manual
                          ? _ExpandPreviewCanvas(imageBytes: state.imageBytes)
                          : _AiExpandCanvas(
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
                        heroTag: 'processBtnExpand',
                        backgroundColor: LamaTheme.accent,
                        onPressed: () => _submit(context),
                        icon: const Icon(Icons.outbox, color: Colors.black),
                        label: Text(
                          assistState.creationMode == MaskCreationMode.manual
                              ? 'Apply Expand'
                              : 'Apply Guided Expand',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildToolbar(BuildContext context, ExpandCanvasReady state) {
    return BlocBuilder<ExpandMaskAssistCubit, ExpandMaskAssistState>(
      builder: (context, assistState) {
        return Container(
          color: LamaTheme.toolbarBg,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPaddingControls(context, state),
                  if (assistState.creationMode ==
                      MaskCreationMode.aiAssist) ...[
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: assistState.generationStatus ==
                                  MaskGenerationStatus.generating
                              ? null
                              : () => context
                                  .read<ExpandMaskAssistCubit>()
                                  .generateSuggestion(),
                          icon: assistState.generationStatus ==
                                  MaskGenerationStatus.generating
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.black,
                                ),
                          label: const Text(
                            'Auto Detect',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: LamaTheme.accent,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: assistState.sourceImageBytes == null
                              ? null
                              : () => context
                                  .read<ExpandMaskAssistCubit>()
                                  .retrySuggestion(),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: assistState.canUndo
                              ? () =>
                                  context.read<ExpandMaskAssistCubit>().undo()
                              : null,
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Undo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: assistState.canRedo
                              ? () =>
                                  context.read<ExpandMaskAssistCubit>().redo()
                              : null,
                          icon: const Icon(Icons.redo_rounded),
                          label: const Text('Redo'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    if (assistState.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        assistState.errorMessage!,
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Mask Edit:',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(width: 10),
                        _EditModeChip(
                          label: 'Add',
                          selected: assistState.editMode == MaskEditMode.add,
                          icon: Icons.add_rounded,
                          onTap: () => context
                              .read<ExpandMaskAssistCubit>()
                              .setEditMode(MaskEditMode.add),
                        ),
                        const SizedBox(width: 8),
                        _EditModeChip(
                          label: 'Erase',
                          selected: assistState.editMode == MaskEditMode.erase,
                          icon: Icons.remove_rounded,
                          onTap: () => context
                              .read<ExpandMaskAssistCubit>()
                              .setEditMode(MaskEditMode.erase),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text(
                          'Brush Radius',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Slider(
                            value: _assistBrushSize,
                            min: 8,
                            max: 96,
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
                        const Text(
                          'Feather',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Expanded(
                          child: Slider(
                            value: assistState.feather,
                            min: 0,
                            max: 12,
                            divisions: 12,
                            activeColor: Colors.orangeAccent,
                            label: assistState.feather.round().toString(),
                            onChanged: (value) => context
                                .read<ExpandMaskAssistCubit>()
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
                                  .read<ExpandMaskAssistCubit>()
                                  .transformMask(MaskTransformAction.expand)
                              : null,
                          icon: const Icon(Icons.add_circle_outline_rounded),
                          label: const Text('Expand Mask'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: assistState.hasSuggestion
                              ? () => context
                                  .read<ExpandMaskAssistCubit>()
                                  .transformMask(MaskTransformAction.contract)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline_rounded),
                          label: const Text('Contract Mask'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: assistState.hasSuggestion
                              ? () => context
                                  .read<ExpandMaskAssistCubit>()
                                  .clearMask()
                              : null,
                          icon: const Icon(Icons.layers_clear_rounded),
                          label: const Text('Clear Mask'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text(
                          'Preview Mask',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const Spacer(),
                        Switch.adaptive(
                          value: assistState.previewVisible,
                          activeColor: LamaTheme.accent,
                          onChanged: (value) => context
                              .read<ExpandMaskAssistCubit>()
                              .togglePreview(value),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaddingControls(BuildContext context, ExpandCanvasReady state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _sliderCol(
          context,
          'Left',
          state.left.toDouble(),
          (value) => context.read<ExpandCanvasCubit>().updatePadding(
                left: value.toInt(),
              ),
        ),
        _sliderCol(
          context,
          'Top',
          state.top.toDouble(),
          (value) => context.read<ExpandCanvasCubit>().updatePadding(
                top: value.toInt(),
              ),
        ),
        _sliderCol(
          context,
          'Right',
          state.right.toDouble(),
          (value) => context.read<ExpandCanvasCubit>().updatePadding(
                right: value.toInt(),
              ),
        ),
        _sliderCol(
          context,
          'Bottom',
          state.bottom.toDouble(),
          (value) => context.read<ExpandCanvasCubit>().updatePadding(
                bottom: value.toInt(),
              ),
        ),
      ],
    );
  }

  Widget _sliderCol(
    BuildContext context,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Text(
          value.toInt().toString(),
          style: const TextStyle(
            color: LamaTheme.accent,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(
          height: 80,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: value,
              min: 0,
              max: 256,
              activeColor: LamaTheme.accent,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
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
          icon: Icon(Icons.crop_free_rounded),
        ),
        ButtonSegment<MaskCreationMode>(
          value: MaskCreationMode.aiAssist,
          label: Text('AI Assist'),
          icon: Icon(Icons.auto_awesome_rounded),
        ),
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
        side: WidgetStateProperty.all(
          const BorderSide(color: Colors.white12),
        ),
      ),
    );
  }
}

class _AiAssistQuickActions extends StatelessWidget {
  final ExpandMaskAssistState assistState;

  const _AiAssistQuickActions({required this.assistState});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: assistState.generationStatus ==
                    MaskGenerationStatus.generating
                ? null
                : () =>
                    context.read<ExpandMaskAssistCubit>().generateSuggestion(),
            icon:
                assistState.generationStatus == MaskGenerationStatus.generating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.auto_awesome, color: Colors.black),
            label: const Text(
              'Auto Detect',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: LamaTheme.accent,
              minimumSize: const Size.fromHeight(46),
            ),
          ),
        ),
        const SizedBox(width: 10),
        OutlinedButton.icon(
          onPressed: assistState.sourceImageBytes == null
              ? null
              : () => context.read<ExpandMaskAssistCubit>().retrySuggestion(),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            minimumSize: const Size(110, 46),
          ),
        ),
      ],
    );
  }
}

class _EditModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  const _EditModeChip({
    required this.label,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

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
          border: Border.all(
            color: selected ? LamaTheme.accent : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? LamaTheme.accent : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? LamaTheme.accent : Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandPreviewCanvas extends StatelessWidget {
  final Uint8List imageBytes;

  const _ExpandPreviewCanvas({required this.imageBytes});

  @override
  Widget build(BuildContext context) {
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
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.48),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Text(
                      'Manual mode keeps the original outpainting flow unchanged. Adjust the edge sliders, then apply expand.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiExpandCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final Uint8List? previewPng;
  final List<List<Offset>> strokes;
  final double brushSize;
  final MaskEditMode editMode;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event, Size size) onPointerEnd;

  const _AiExpandCanvas({
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
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Text(
                          editMode == MaskEditMode.add
                              ? 'AI Assist active. Paint to add more subject protection before expanding the canvas.'
                              : 'AI Assist active. Paint to erase guidance from areas that should expand more freely.',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
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
