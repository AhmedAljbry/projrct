import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gal/gal.dart'; 
import 'package:untitled2/lama_api/lama_api_client.dart';
import 'package:untitled2/lama_api/lama_models.dart';

// Since this is a professional UI, we establish a clean sleek theme.
const Color _kDarkBackground = Color(0xFF121212);
const Color _kSurfaceColor = Color(0xFF1E1E1E);
const Color _kPrimaryAccent = Color(0xFF00E5FF); // Cyan for a magical highlight

class LamaEditorScreen extends StatefulWidget {
  final String apiUrl;
  final String apiKey;

  const LamaEditorScreen({
    super.key,
    required this.apiUrl,
    required this.apiKey,
  });

  @override
  State<LamaEditorScreen> createState() => _LamaEditorScreenState();
}

class _LamaEditorScreenState extends State<LamaEditorScreen> {
  late LamaApiClient _apiClient;

  // Image and Mask state
  Uint8List? _originalImageBytes;
  Uint8List? _currentResultBytes;
  ui.Image? _decodedUiImage;

  // Drawing state
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  double _brushSize = 20.0;
  bool _isProcessing = false;
  double _processProgress = 0.0;
  String _processMessage = "";

  // Tool state
  LamaTaskMode _selectedMode = LamaTaskMode.healRegion;
  
  // Expand Canvas parameters
  double _expandLeft = 0;
  double _expandTop = 0;
  double _expandRight = 0;
  double _expandBottom = 0;

  @override
  void initState() {
    super.initState();
    _apiClient = LamaApiClient(baseUrl: widget.apiUrl, apiKey: widget.apiKey);
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile != null) {
      final bytes = await xfile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      
      setState(() {
        _originalImageBytes = bytes;
        _currentResultBytes = null;
        _decodedUiImage = frameInfo.image;
        _strokes.clear();
      });
    }
  }

  Future<void> _saveImage() async {
    if (_currentResultBytes == null) return;
    try {
      // Use gal package to save
      await Gal.putImageBytes(_currentResultBytes!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image saved to gallery 🚀'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _clearStrokes() {
    setState(() {
      _strokes.clear();
    });
  }

  bool _requiresMask() {
    return _selectedMode == LamaTaskMode.healRegion ||
           _selectedMode == LamaTaskMode.repairDamage ||
           _selectedMode == LamaTaskMode.cleanEdges;
  }

  /// Converts the UI strokes into a completely black and white PNG mask 
  /// matching exactly the original image dimensions.
  Future<Uint8List> _generateMaskPng(Size widgetSize) async {
    if (_decodedUiImage == null) throw Exception("No image loaded");
    final int imgWidth = _decodedUiImage!.width;
    final int imgHeight = _decodedUiImage!.height;

    // Scaling factors based on how the image is fitted in the AspectRatio box
    final double scaleX = imgWidth / widgetSize.width;
    final double scaleY = imgHeight / widgetSize.height;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Black background
    final bgPaint = Paint()..color = Colors.black;
    canvas.drawRect(Rect.fromLTWH(0, 0, imgWidth.toDouble(), imgHeight.toDouble()), bgPaint);

    // White strokes
    final strokePaint = Paint()
      ..color = Colors.white
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final points in _strokes) {
      if (points.isEmpty) continue;
      final path = Path();
      // Apply scaling to coordinates & brush size
      path.moveTo(points.first.dx * scaleX, points.first.dy * scaleY);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx * scaleX, points[i].dy * scaleY);
      }
      
      // Scale brush size with average aspect ratio scaling
      final effectiveBrushSize = _brushSize * ((scaleX + scaleY) / 2);
      strokePaint.strokeWidth = effectiveBrushSize;
      
      canvas.drawPath(path, strokePaint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(imgWidth, imgHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<void> _processTask(BoxConstraints constraints) async {
    if (_originalImageBytes == null) return;
    
    Uint8List? maskBytes;
    
    if (_requiresMask()) {
      if (_strokes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Please draw a mask first!'), backgroundColor: Colors.orange)
        );
        return;
      }
      
      setState(() {
         _isProcessing = true;
         _processProgress = 0;
         _processMessage = "Generating mask...";
      });
      
      // Calculate the size the image widget occupies
      final double aspect = _decodedUiImage!.width / _decodedUiImage!.height;
      double w = constraints.maxWidth;
      double h = w / aspect;
      if (h > constraints.maxHeight) {
        h = constraints.maxHeight;
        w = h * aspect;
      }
      maskBytes = await _generateMaskPng(Size(w, h));
    } else {
      setState(() {
         _isProcessing = true;
         _processProgress = 0;
         _processMessage = "Preparing request...";
      });
    }

    try {
      final bytesToProcess = _currentResultBytes ?? _originalImageBytes!;
      
      Uint8List result;
      
      switch (_selectedMode) {
        case LamaTaskMode.healRegion:
          result = await _apiClient.healRegion(
            imageBytes: bytesToProcess,
            imageName: 'image.jpg',
            maskBytes: maskBytes!,
            maskName: 'mask.png',
            healRadius: 2, // Slight standard expansion
            onProgress: _onApiProgress,
          );
          break;
        case LamaTaskMode.repairDamage:
          result = await _apiClient.repairDamage(
            imageBytes: bytesToProcess,
            imageName: 'image.jpg',
            maskBytes: maskBytes!,
            maskName: 'mask.png',
            onProgress: _onApiProgress,
          );
          break;
        case LamaTaskMode.cleanEdges:
          result = await _apiClient.cleanEdges(
            imageBytes: bytesToProcess,
            imageName: 'image.jpg',
            maskBytes: maskBytes!,
            maskName: 'mask.png',
            edgeRadius: 4,
            onProgress: _onApiProgress,
          );
          break;
        case LamaTaskMode.expandCanvas:
          result = await _apiClient.expandCanvas(
            imageBytes: bytesToProcess,
            imageName: 'image.jpg',
            expandOptions: ExpandOptions(
              left: _expandLeft.toInt(),
              top: _expandTop.toInt(),
              right: _expandRight.toInt(),
              bottom: _expandBottom.toInt(),
              anchor: 'center',
            ),
            onProgress: _onApiProgress,
          );
          break;
        case LamaTaskMode.removeObject:
          // Just defaulting to heal if triggered by accident
          throw Exception("Remove Object requested but not mapped natively here.");
      }

      // Prepare UI for new result
      final codec = await ui.instantiateImageCodec(result);
      final frameInfo = await codec.getNextFrame();

      setState(() {
        _currentResultBytes = result;
        _decodedUiImage = frameInfo.image; // update to new dimension
        _strokes.clear();
        _isProcessing = false;
        
        // Reset expand parameters after successful expand so it's fresh
        if (_selectedMode == LamaTaskMode.expandCanvas) {
          _expandLeft = 0;
          _expandTop = 0;
          _expandRight = 0;
          _expandBottom = 0;
        }
      });
      
    } catch (e) {
      setState(() {
         _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _onApiProgress(LamaJobStatus status) {
    if (mounted) {
      setState(() {
        _processProgress = status.progress / 100.0;
        _processMessage = status.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: _kDarkBackground,
        colorScheme: const ColorScheme.dark(
          primary: _kPrimaryAccent,
          surface: _kSurfaceColor,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: _kSurfaceColor,
          title: const Text("LaMa AI Editor", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          centerTitle: true,
          elevation: 0,
          actions: [
            if (_originalImageBytes != null)
               IconButton(
                 icon: const Icon(Icons.refresh, color: Colors.white70),
                 tooltip: 'Reset Original',
                 onPressed: () {
                   setState(() {
                     _currentResultBytes = null;
                     _strokes.clear();
                     // need to reload original dimension
                     if (_originalImageBytes != null) {
                       ui.instantiateImageCodec(_originalImageBytes!).then((codec) {
                         codec.getNextFrame().then((f) {
                           setState(() {
                             _decodedUiImage = f.image;
                           });
                         });
                       });
                     }
                   });
                 },
               ),
            if (_currentResultBytes != null)
              IconButton(
                icon: const Icon(Icons.download_rounded, color: _kPrimaryAccent),
                onPressed: _saveImage,
              ),
          ],
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: _decodedUiImage == null
                        ? _buildPlaceholder()
                        : _buildEditorCanvas(),
                  ),
                ),
                _buildToolbar(),
              ],
            ),
            
            // Loading Overlay
            if (_isProcessing)
              Container(
                color: Colors.black87,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: CircularProgressIndicator(
                          value: _processProgress > 0 ? _processProgress : null,
                          strokeWidth: 6,
                          color: _kPrimaryAccent,
                          backgroundColor: Colors.white12,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "${(_processProgress * 100).toInt()}%",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text(
                         _processMessage,
                         style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.auto_awesome, size: 64, color: Colors.white.withOpacity(0.2)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: _pickImage,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text("Select Image"),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kPrimaryAccent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
        )
      ],
    );
  }

  Widget _buildEditorCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final aspect = _decodedUiImage!.width / _decodedUiImage!.height;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Using AspectRatio ensures the drawing canvas perfectly aligns with the fitted image
            AspectRatio(
              aspectRatio: aspect,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.memory(
                    _currentResultBytes ?? _originalImageBytes!,
                    fit: BoxFit.contain,
                  ),
                  if (_requiresMask())
                    GestureDetector(
                      onPanStart: (details) {
                        setState(() {
                          _currentStroke = [details.localPosition];
                          _strokes.add(_currentStroke);
                        });
                      },
                      onPanUpdate: (details) {
                        setState(() {
                          _currentStroke.add(details.localPosition);
                        });
                      },
                      onPanEnd: (details) {
                        // stroke ended
                      },
                      child: CustomPaint(
                        painter: MaskPainter(
                          strokes: _strokes,
                          brushSize: _brushSize,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Floating Action Button to run task
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.extended(
                onPressed: () => _processTask(constraints),
                backgroundColor: _kPrimaryAccent,
                icon: const Icon(Icons.auto_fix_high, color: Colors.black),
                label: const Text("Apply", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildToolbar() {
    if (_decodedUiImage == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      decoration: const BoxDecoration(
        color: _kSurfaceColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 10, offset: Offset(0, -2))
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Mode Options
          if (_requiresMask()) ...[
            Row(
              children: [
                const Icon(Icons.brush, color: Colors.white54, size: 20),
                const SizedBox(width: 8),
                const Text("Brush Size", style: TextStyle(color: Colors.white54)),
                Expanded(
                  child: Slider(
                    value: _brushSize,
                    min: 5,
                    max: 100,
                    activeColor: _kPrimaryAccent,
                    onChanged: (val) => setState(() => _brushSize = val),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.undo, color: Colors.white70),
                  tooltip: 'Clear Mask',
                  onPressed: _strokes.isNotEmpty ? _clearStrokes : null,
                )
              ],
            ),
            const SizedBox(height: 8),
          ] else if (_selectedMode == LamaTaskMode.expandCanvas) ...[
             const Text("Expand Canvas (px)", style: TextStyle(color: Colors.white54)),
             const SizedBox(height: 8),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
               children: [
                 _buildExpandInput("L", _expandLeft, (v) => setState(() => _expandLeft = v)),
                 _buildExpandInput("T", _expandTop, (v) => setState(() => _expandTop = v)),
                 _buildExpandInput("R", _expandRight, (v) => setState(() => _expandRight = v)),
                 _buildExpandInput("B", _expandBottom, (v) => setState(() => _expandBottom = v)),
               ],
             ),
             const SizedBox(height: 16),
          ],
          
          // Tool Selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildToolBtn(LamaTaskMode.healRegion, Icons.healing, "Heal"),
                _buildToolBtn(LamaTaskMode.repairDamage, Icons.build_circle, "Repair"),
                _buildToolBtn(LamaTaskMode.cleanEdges, Icons.blur_on, "Clean Edges"),
                _buildToolBtn(LamaTaskMode.expandCanvas, Icons.crop_free, "Expand"),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildExpandInput(String label, double val, ValueChanged<double> onChanged) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
        SizedBox(
          height: 80,
          child: RotatedBox(
            quarterTurns: 3,
            child: Slider(
              value: val,
              min: 0,
              max: 1024,
              activeColor: _kPrimaryAccent,
              onChanged: onChanged,
            ),
          ),
        ),
        Text(val.toInt().toString(), style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildToolBtn(LamaTaskMode mode, IconData icon, String label) {
    final isSelected = _selectedMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? _kPrimaryAccent.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _kPrimaryAccent : Colors.transparent, 
              width: 1.5
            )
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? _kPrimaryAccent : Colors.white54, size: 28),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? _kPrimaryAccent : Colors.white54,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MaskPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final double brushSize;

  MaskPainter({required this.strokes, required this.brushSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x88FF0055) // Semi-transparent red/pink for drawing purely visually
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = brushSize;

    for (final points in strokes) {
      if (points.isEmpty) continue;
      final path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
         path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant MaskPainter oldDelegate) {
     return true; 
  }
}
