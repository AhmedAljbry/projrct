import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_bloc.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_event.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/bloc/remote_lama_state.dart';

const Color _bg = Color(0xFF131417);
const Color _accent = Color(0xFF56E39F);

class RemoteLamaEditorPage extends StatefulWidget {
  final Uint8List? initialImage;

  const RemoteLamaEditorPage({super.key, this.initialImage});

  @override
  State<RemoteLamaEditorPage> createState() => _RemoteLamaEditorPageState();
}

class _RemoteLamaEditorPageState extends State<RemoteLamaEditorPage> {
  Uint8List? _originalImageBytes;
  Uint8List? _currentResultBytes;
  ui.Image? _decodedUiImage;

  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  double _brushSize = 20.0;
  
  LamaTaskMode _selectedMode = LamaTaskMode.healRegion;
  
  double _expandLeft = 0;
  double _expandTop = 0;
  double _expandRight = 0;
  double _expandBottom = 0;

  @override
  void initState() {
    super.initState();
    if (widget.initialImage != null) {
      _loadSourceImageSafely(widget.initialImage!);
    }
  }

  Future<void> _loadSourceImageSafely(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _originalImageBytes = bytes;
        _decodedUiImage = frame.image;
        _currentResultBytes = null;
        _strokes.clear();
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      await _loadSourceImageSafely(bytes);
      if (mounted) context.read<RemoteLamaBloc>().add(ResetLamaStateEvent());
    }
  }

  Future<void> _saveImage() async {
    if (_currentResultBytes == null) return;
    try {
      await Gal.putImageBytes(_currentResultBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved locally successfully!'), backgroundColor: _accent));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save to gallery: $e'), backgroundColor: Colors.redAccent));
      }
    }
  }

  bool _requiresMask() => _selectedMode != LamaTaskMode.expandCanvas;

  Future<Uint8List> _generateMaskPng(Size widgetSize) async {
    if (_decodedUiImage == null) throw Exception("No image");
    final int imgWidth = _decodedUiImage!.width;
    final int imgHeight = _decodedUiImage!.height;
    final double scaleX = imgWidth / widgetSize.width;
    final double scaleY = imgHeight / widgetSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, imgWidth.toDouble(), imgHeight.toDouble()), bgPaint);

    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final points in _strokes) {
      if (points.isEmpty) continue;
      final path = Path();
      path.moveTo(points.first.dx * scaleX, points.first.dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      strokePaint.strokeWidth = _brushSize * ((scaleX + scaleY) / 2);
      canvas.drawPath(path, strokePaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(imgWidth, imgHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  void _submitJob(BoxConstraints constraints) async {
    if (_originalImageBytes == null) return;

    Uint8List? maskBytes;
    if (_requiresMask()) {
      if (_strokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please mask an area first!'), backgroundColor: Colors.orange));
        return;
      }
      final double aspect = _decodedUiImage!.width / _decodedUiImage!.height;
      double w = constraints.maxWidth;
      double h = w / aspect;
      if (h > constraints.maxHeight) {
        h = constraints.maxHeight;
        w = h * aspect;
      }
      maskBytes = await _generateMaskPng(Size(w, h));
    }

    final imgBytes = _currentResultBytes ?? _originalImageBytes!;
    LamaOptions options;

    switch (_selectedMode) {
      case LamaTaskMode.healRegion:
        options = HealRegionOptions(imageBytes: imgBytes, imageName: 'source.png', maskBytes: maskBytes, maskName: 'mask.png');
        break;
      case LamaTaskMode.repairDamage:
        options = RepairDamageOptions(imageBytes: imgBytes, imageName: 'source.png', maskBytes: maskBytes, maskName: 'mask.png');
        break;
      case LamaTaskMode.cleanEdges:
        options = CleanEdgesOptions(imageBytes: imgBytes, imageName: 'source.png', maskBytes: maskBytes, maskName: 'mask.png');
        break;
      case LamaTaskMode.expandCanvas:
        options = ExpandCanvasOptions(
          imageBytes: imgBytes,
          imageName: 'source.png',
          left: _expandLeft.toInt(),
          top: _expandTop.toInt(),
          right: _expandRight.toInt(),
          bottom: _expandBottom.toInt(),
        );
        break;
    }

    if (mounted) context.read<RemoteLamaBloc>().add(SubmitLamaJobEvent(options));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RemoteLamaBloc, RemoteLamaState>(
      listener: (context, state) {
        if (state is RemoteLamaSuccess) {
          _loadSourceImageSafely(state.resultBytes).then((_) {
            setState(() {
               _currentResultBytes = state.resultBytes;
            });
            context.read<RemoteLamaBloc>().add(ResetLamaStateEvent());
          });
        }
        if (state is RemoteLamaFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message),
            backgroundColor: Colors.redAccent,
            action: state.isRetryable ? SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: () {}) : null,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: _bg,
          appBar: AppBar(
            backgroundColor: _bg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () { 
                if (Navigator.of(context).canPop()) { 
                   Navigator.of(context).pop(); 
                } 
              },
            ),
            title: const Text('Remote LaMa Studio', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            actions: [
              if (_originalImageBytes != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white70),
                  onPressed: () => _loadSourceImageSafely(_originalImageBytes!),
                ),
              if (_currentResultBytes != null)
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: _accent),
                  onPressed: _saveImage,
                ),
            ],
          ),
          body: Stack(
            children: [
              Column(
                children: [
                   Expanded(
                     child: _decodedUiImage == null 
                       ? Center(
                           child: ElevatedButton.icon(
                             onPressed: _pickImage,
                             icon: const Icon(Icons.add_photo_alternate),
                             label: const Text('Select Image'),
                             style: ElevatedButton.styleFrom(backgroundColor: _accent, foregroundColor: Colors.black)
                           ),
                         )
                       : LayoutBuilder(
                           builder: (context, constraints) {
                             final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
                             return Stack(
                               alignment: Alignment.center,
                               children: [
                                 AspectRatio(
                                   aspectRatio: aspect,
                                   child: Stack(
                                     fit: StackFit.expand,
                                     children: [
                                       Image.memory(_currentResultBytes ?? _originalImageBytes!, fit: BoxFit.contain),
                                       if (_requiresMask())
                                         GestureDetector(
                                           onPanStart: (details) => setState(() => _strokes.add(_currentStroke = [details.localPosition])),
                                           onPanUpdate: (details) => setState(() => _currentStroke.add(details.localPosition)),
                                           child: CustomPaint(painter: _MaskPainter(strokes: _strokes, brushSize: _brushSize)),
                                         ),
                                     ],
                                   ),
                                 ),
                                 Positioned(
                                    bottom: 16, right: 16,
                                    child: FloatingActionButton.extended(
                                      heroTag: 'processBtnLama',
                                      backgroundColor: _accent,
                                      onPressed: () => _submitJob(constraints),
                                      icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                                      label: const Text('Apply', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                    ),
                                 )
                               ],
                             );
                           }
                         )
                   ),
                   _buildToolbar(),
                ],
              ),
              if (state is RemoteLamaSubmitting || state is RemoteLamaProcessing)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         SizedBox(
                           width: 80, height: 80,
                           child: CircularProgressIndicator(
                             value: state is RemoteLamaProcessing ? (state.jobStatus.progress / 100).clamp(0.0, 1.0) : null,
                             color: _accent, strokeWidth: 5, backgroundColor: Colors.white12,
                           ),
                         ),
                         const SizedBox(height: 24),
                         Text(
                           state is RemoteLamaProcessing ? '${state.jobStatus.progress}%' : 'Preparing...',
                           style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                         ),
                         const SizedBox(height: 8),
                         Text(
                           state is RemoteLamaProcessing ? state.jobStatus.message : 'Uploading...',
                           style: const TextStyle(color: Colors.white70, fontSize: 14),
                         ),
                      ],
                    ),
                  ),
                )
            ],
          ),
        );
      },
    );
  }

  Widget _buildToolbar() {
    if (_decodedUiImage == null) return const SizedBox.shrink();
    return Container(
      color: const Color(0xFF1E1E1E),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            if (_requiresMask()) ...[
              Row(
                children: [
                  const Icon(Icons.brush, color: Colors.white54, size: 20),
                  Expanded(
                    child: Slider(
                      value: _brushSize, min: 5, max: 80, activeColor: _accent,
                      onChanged: (v) => setState(() => _brushSize = v),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.undo, color: Colors.white54),
                    onPressed: _strokes.isNotEmpty ? () => setState(() => _strokes.clear()) : null,
                  ),
                ],
              ),
            ] else if (_selectedMode == LamaTaskMode.expandCanvas) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _sliderCol("Left", _expandLeft, (v) => setState(() => _expandLeft = v)),
                  _sliderCol("Top", _expandTop, (v) => setState(() => _expandTop = v)),
                  _sliderCol("Right", _expandRight, (v) => setState(() => _expandRight = v)),
                  _sliderCol("Bottom", _expandBottom, (v) => setState(() => _expandBottom = v)),
                ],
              ),
              const SizedBox(height: 12),
            ],
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                   _toolBtn(LamaTaskMode.healRegion, Icons.healing, "Heal"),
                   _toolBtn(LamaTaskMode.repairDamage, Icons.build_circle, "Repair"),
                   _toolBtn(LamaTaskMode.cleanEdges, Icons.blur_on, "Clean Edges"),
                   _toolBtn(LamaTaskMode.expandCanvas, Icons.crop_free, "Expand"),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _sliderCol(String label, double val, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        SizedBox(height: 60, child: RotatedBox(quarterTurns: 3, child: Slider(value: val, min: 0, max: 512, activeColor: _accent, onChanged: onChanged))),
      ],
    );
  }

  Widget _toolBtn(LamaTaskMode mode, IconData icon, String label) {
    final sel = _selectedMode == mode;
    return InkWell(
      onTap: () => setState(() => _selectedMode = mode),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? _accent.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? _accent : Colors.transparent),
        ),
        child: Column(
          children: [
            Icon(icon, color: sel ? _accent : Colors.white54),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: sel ? _accent : Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double brushSize;
  _MaskPainter({required this.strokes, required this.brushSize});
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0x88FF0055)..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..style = PaintingStyle.stroke..strokeWidth = brushSize;
    for (final pts in strokes) {
      if (pts.isEmpty) continue;
      final path = Path()..moveTo(pts.first.dx, pts.first.dy);
      for (int i = 1; i < pts.length; i++) path.lineTo(pts[i].dx, pts[i].dy);
      canvas.drawPath(path, p);
    }
  }
  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) => true;
}
