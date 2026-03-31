import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/descratch/descratch_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_mask_painter.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class DescratchPage extends StatefulWidget {
  const DescratchPage({super.key});

  @override
  State<DescratchPage> createState() => _DescratchPageState();
}

class _DescratchPageState extends State<DescratchPage> {
  ui.Image? _decodedUiImage;
  final List<List<Offset>> _strokes = <List<Offset>>[];
  List<Offset>? _currentStroke;
  double _brushSize = 18;

  @override
  void initState() {
    super.initState();
    final state = context.read<DescratchCubit>().state;
    if (state.imageBytes != null) {
      _decodeImage(state.imageBytes!);
    }
  }

  @override
  void dispose() {
    _decodedUiImage?.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null) {
      return;
    }
    final bytes = await file.readAsBytes();
    await _decodeImage(bytes);
    if (!mounted) {
      return;
    }
    setState(_strokes.clear);
    context.read<DescratchCubit>().setImage(bytes);
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }
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
      _currentStroke = <Offset>[event.localPosition];
      _strokes.add(_currentStroke!);
    });
  }

  void _handlePointerMove(PointerMoveEvent event, Size size) {
    if (_currentStroke == null) {
      return;
    }
    if (!_isInsideCanvas(event.localPosition, size)) {
      return;
    }
    setState(() {
      _currentStroke!.add(event.localPosition);
    });
  }

  void _handlePointerEnd(PointerEvent event) {
    _currentStroke = null;
  }

  Future<Uint8List?> _generateMaskPng(Size widgetSize) async {
    final image = _decodedUiImage;
    if (image == null || _strokes.isEmpty) {
      return null;
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final scaleX = image.width / widgetSize.width;
    final scaleY = image.height / widgetSize.height;

    canvas.drawRect(
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Paint()..color = Colors.black,
    );

    final paint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in _strokes) {
      if (stroke.isEmpty) {
        continue;
      }
      final path = Path()
        ..moveTo(stroke.first.dx * scaleX, stroke.first.dy * scaleY);
      for (var index = 1; index < stroke.length; index++) {
        path.lineTo(stroke[index].dx * scaleX, stroke[index].dy * scaleY);
      }
      paint.strokeWidth = _brushSize * ((scaleX + scaleY) / 2);
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final maskImage = await picture.toImage(image.width, image.height);
    final byteData = await maskImage.toByteData(format: ui.ImageByteFormat.png);
    maskImage.dispose();
    return byteData?.buffer.asUint8List();
  }

  Future<void> _submit(BoxConstraints constraints) async {
    final image = _decodedUiImage;
    if (image == null) {
      return;
    }
    if (_strokes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mask the scratched or damaged zones first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final aspect = image.width / image.height;
    var width = constraints.maxWidth;
    var height = width / aspect;
    if (height > constraints.maxHeight) {
      height = constraints.maxHeight;
      width = height * aspect;
    }

    final maskBytes = await _generateMaskPng(Size(width, height));
    if (maskBytes != null && mounted) {
      await context.read<DescratchCubit>().submit(maskBytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DescratchCubit, DescratchState>(
      listener: (context, state) {
        if (state.message != null && state.stage == DescratchStage.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(state.message!),
                backgroundColor: Colors.redAccent),
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
            title: const Text('Descratch Restore',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            actions: [
              IconButton(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: 'Choose another image',
              ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                  _ToolIntroCard(
                    title: 'Remote restoration for scratches and age damage',
                    body:
                        'This tool uses the backend repair-damage mode already integrated in the project. Brush only the damaged lines, folds, tears, or dust marks you want the server to rebuild.',
                    footer:
                        'Advanced detail-preserve, face-safe, and auto-enhance controls are still server-managed in the current backend build.',
                  ),
                  Expanded(child: _buildBody(state)),
                  if (state.hasImage && !state.hasResult)
                    _buildBottomBar(state),
                ],
              ),
              if (state.isBusy)
                LamaStatusIndicator(
                  progress: state.jobStatus?.progress ?? 0,
                  message: state.jobStatus?.message ??
                      'Uploading restoration request...',
                  isProcessing: state.stage == DescratchStage.processing,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(DescratchState state) {
    if (state.hasResult && state.resultBytes != null) {
      return LamaResultViewer(
        resultBytes: state.resultBytes!,
        originalBytes: state.imageBytes,
        onReset: () {
          setState(_strokes.clear);
          context.read<DescratchCubit>().reset();
        },
        onRetry: () {
          setState(_strokes.clear);
          context.read<DescratchCubit>().editAgain();
        },
      );
    }

    if (!state.hasImage || _decodedUiImage == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: LamaTheme.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_outlined,
                    color: LamaTheme.accent, size: 36),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pick a photo to start restoring scratches',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'You will preview the original, paint only the damaged areas, run the remote restoration, then compare and export the result.',
                style: TextStyle(
                    color: Colors.white70, fontSize: 13, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.add_photo_alternate_rounded,
                    color: Colors.black),
                label: const Text('Select Image',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LamaTheme.accent,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final image = _decodedUiImage!;
        final aspect = image.width / image.height;
        final message =
            state.stage == DescratchStage.failure ? state.message : null;
        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message != null) ...[
                _InlineNotice(
                  message: message,
                  isError: true,
                  actionLabel: state.isRetryable ? 'Retry request' : null,
                  onAction: state.isRetryable
                      ? () =>
                          context.read<DescratchCubit>().retryLastSubmission()
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              const _SectionTitle(
                title: 'Mask the damage',
                subtitle:
                    'Paint tightly over scratches, dust, cracks, and torn zones for the cleanest reconstruction.',
              ),
              const SizedBox(height: 12),
              AspectRatio(
                aspectRatio: aspect,
                child: _InteractiveMaskCanvas(
                  imageBytes: state.imageBytes!,
                  strokes: _strokes,
                  brushSize: _brushSize,
                  helperText:
                      'White and pink overlay = damaged area to rebuild remotely',
                  onPointerDown: _handlePointerDown,
                  onPointerMove: _handlePointerMove,
                  onPointerEnd: _handlePointerEnd,
                ),
              ),
              const SizedBox(height: 16),
              const _SectionTitle(
                title: 'Restore profile',
                subtitle:
                    'The current server build exposes restoration as a guided repair flow with server-managed tuning.',
              ),
              const SizedBox(height: 12),
              const _CapabilityPanel(
                items: [
                  'Repair mode: uses the live repair_damage endpoint already wired in the app.',
                  'Detail preservation: controlled by the backend and not yet exposed as a request field.',
                  'Face safety and auto-enhance: ready for future backend mapping without changing this page structure.',
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: constraints.maxWidth,
                child: ElevatedButton.icon(
                  onPressed: state.isBusy ? null : () => _submit(constraints),
                  icon: const Icon(Icons.auto_fix_high_rounded,
                      color: Colors.black),
                  label: const Text('Run Descratch',
                      style: TextStyle(
                          color: Colors.black, fontWeight: FontWeight.w800)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LamaTheme.accent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(DescratchState state) {
    return Container(
      color: LamaTheme.toolbarBg,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const Icon(Icons.brush_rounded, color: Colors.white54),
            const SizedBox(width: 10),
            const Text('Brush Size', style: TextStyle(color: Colors.white70)),
            const SizedBox(width: 16),
            Expanded(
              child: Slider(
                value: _brushSize,
                min: 6,
                max: 48,
                activeColor: LamaTheme.accent,
                label: _brushSize.round().toString(),
                onChanged: state.isBusy
                    ? null
                    : (value) => setState(() => _brushSize = value),
              ),
            ),
            IconButton(
              onPressed: _strokes.isEmpty || state.isBusy
                  ? null
                  : () => setState(() => _strokes.removeLast()),
              icon: const Icon(Icons.undo_rounded, color: Colors.white70),
            ),
            IconButton(
              onPressed: _strokes.isEmpty || state.isBusy
                  ? null
                  : () => setState(_strokes.clear),
              icon:
                  const Icon(Icons.layers_clear_rounded, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveMaskCanvas extends StatelessWidget {
  final Uint8List imageBytes;
  final List<List<Offset>> strokes;
  final double brushSize;
  final String helperText;
  final void Function(PointerDownEvent event, Size size) onPointerDown;
  final void Function(PointerMoveEvent event, Size size) onPointerMove;
  final void Function(PointerEvent event) onPointerEnd;

  const _InteractiveMaskCanvas({
    required this.imageBytes,
    required this.strokes,
    required this.brushSize,
    required this.helperText,
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
                            strokes: strokes, brushSize: brushSize),
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
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Text(helperText,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
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

class _ToolIntroCard extends StatelessWidget {
  final String title;
  final String body;
  final String footer;

  const _ToolIntroCard(
      {required this.title, required this.body, required this.footer});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E2A25), Color(0xFF16181D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13, height: 1.45)),
          const SizedBox(height: 10),
          Text(footer,
              style: const TextStyle(
                  color: LamaTheme.accent, fontSize: 12.5, height: 1.4)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: const TextStyle(
                color: Colors.white70, fontSize: 13, height: 1.4)),
      ],
    );
  }
}

class _CapabilityPanel extends StatelessWidget {
  final List<String> items;

  const _CapabilityPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(Icons.check_circle_outline_rounded,
                          size: 16, color: LamaTheme.accent),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.4))),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  final String message;
  final bool isError;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InlineNotice(
      {required this.message,
      this.isError = false,
      this.actionLabel,
      this.onAction});

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.redAccent : LamaTheme.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: color),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, height: 1.4))),
          if (actionLabel != null && onAction != null)
            TextButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
