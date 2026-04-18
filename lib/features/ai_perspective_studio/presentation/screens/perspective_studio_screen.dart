import 'dart:ui' as ui;
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import '../../../../shared/widgets/result_preview_screen.dart';
import '../../core/perspective_processor.dart';
import '../../core/ai_corner_detector.dart';
import '../../domain/models/perspective_points.dart';
import '../widgets/perspective_selector.dart';

class PerspectiveStudioScreen extends StatefulWidget {
  final ui.Image initialImage;
  final void Function(Uint8List bytes)? onApply;
  final VoidCallback? onClose;

  const PerspectiveStudioScreen({
    super.key,
    required this.initialImage,
    this.onApply,
    this.onClose,
  });

  @override
  State<PerspectiveStudioScreen> createState() =>
      _PerspectiveStudioScreenState();
}

class _PerspectiveStudioScreenState extends State<PerspectiveStudioScreen> {
  late PerspectivePoints _points;
  bool _isProcessing = false;
  ui.Image? _currentImage;
  Uint8List? _resultBytes; // Holds the processed image
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _currentImage = widget.initialImage;
    _resetPoints();
  }

  void _resetPoints() {
    final w = widget.initialImage.width.toDouble();
    final h = widget.initialImage.height.toDouble();

    // Default: 15% inset rectangle
    final insetW = w * 0.15;
    final insetH = h * 0.15;

    setState(() {
      _points = PerspectivePoints(
        topLeft: Offset(insetW, insetH),
        topRight: Offset(w - insetW, insetH),
        bottomLeft: Offset(insetW, h - insetH),
        bottomRight: Offset(w - insetW, h - insetH),
      );
      _showPreview = false;
    });
  }

  Future<void> _autoDetect() async {
    final l10n = AppL10n.of(context);
    setState(() => _isProcessing = true);
    try {
      final detected =
          await AiCornerDetector.autoDetectCorners(widget.initialImage);
      if (detected != null && mounted) {
        setState(() => _points = detected);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('perspective_auto_detect_failed'))),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _applyPerspective() async {
    final l10n = AppL10n.of(context);
    setState(() => _isProcessing = true);

    try {
      // Convert ui.Image to bytes
      final data =
          await widget.initialImage.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) throw Exception(l10n.get('perspective_failed_image_data'));
      final bytes = data.buffer.asUint8List();

      final resultBytes = await PerspectiveProcessor.rectifyImage(
        imageBytes: bytes,
        points: _points,
      );

      if (resultBytes != null && mounted) {
        setState(() {
          _resultBytes = resultBytes;
          _showPreview = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('${l10n.get('perspective_error_prefix')}$e'),
              backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _onConfirmSave() {
    if (_resultBytes != null) {
      final resultBytes = _resultBytes!;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
        builder: (_) => ResultPreviewScreen(
            title: AppL10n.of(context).get('perspective_result'),
            resultBytes: resultBytes,
            onDone: widget.onApply == null
                ? null
                : () => widget.onApply!(resultBytes),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0C0C0E),
        body: SafeArea(
          child: Column(
            children: [
              // â”€â”€ Top Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              _buildTopBar(l10n),

              // â”€â”€ Editor Area â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Expanded(
                child: Stack(
                  children: [
                    if (!_showPreview && _currentImage != null)
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: PerspectiveSelector(
                          image: _currentImage!,
                          points: _points,
                          onPointsChanged: (pts) =>
                              setState(() => _points = pts),
                        ),
                      ),
                    if (_showPreview && _resultBytes != null)
                      _buildResultPreview(),
                    if (_isProcessing)
                      Container(
                        color: Colors.black54,
                        child: const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF56E39F)),
                        ),
                      ),
                  ],
                ),
              ),

              // â”€â”€ Bottom Controls â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              if (!_showPreview) _buildBottomControls(l10n),
              if (_showPreview) _buildPreviewControls(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(AppL10n l10n) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 22),
            onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
          ),
          const Spacer(),
          if (!_showPreview)
            IconButton(
              icon: const Icon(Icons.auto_awesome_rounded,
                  color: Color(0xFF56E39F), size: 24),
              onPressed: _autoDetect,
              tooltip: l10n.get('perspective_auto_detect'),
            ),
          IconButton(
            icon: Icon(Icons.file_download_outlined,
                color: _showPreview ? const Color(0xFF56E39F) : Colors.white,
                size: 26),
            onPressed: _showPreview ? _onConfirmSave : _applyPerspective,
          ),
        ],
      ),
    );
  }

  Widget _buildResultPreview() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            _resultBytes!,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(AppL10n l10n) {
    return Container(
      color: const Color(0xFF131417),
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomAction(
            icon: Icons.refresh_rounded,
            label: l10n.get('perspective_reset'),
            onTap: _resetPoints,
          ),
          _BottomAction(
            icon: Icons.check_circle_outline_rounded,
            label: l10n.get('perspective_adjust'),
            highlight: true,
            onTap: _applyPerspective,
          ),
        ],
      ),
    );
  }

  Future<void> _extractText() async {
    final l10n = AppL10n.of(context);
    if (_resultBytes == null) return;

    setState(() => _isProcessing = true);
    File? tempFile;
    try {
      final tempDir = await getTemporaryDirectory();
      tempFile =
          File('${tempDir.path}${Platform.pathSeparator}ocr_input.png');
      await tempFile.writeAsBytes(_resultBytes!, flush: true);

      final recognizedText = await FlutterTesseractOcr.extractText(
        tempFile.path,
        language: 'ara+eng+osd',
        args: {
          'psm': '6',
          'preserve_interword_spaces': '1',
        },
      );

      if (mounted) {
        if (recognizedText.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.get('perspective_no_text'))),
          );
        } else {
          _showTextDialog(recognizedText);
        }
      }
    } on MissingPluginException {
      if (mounted) {
        _showRestartDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n.get('perspective_ocr_error_prefix')}$e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (tempFile != null && tempFile.existsSync()) {
        await tempFile.delete();
      }
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showRestartDialog() {
    final l10n = AppL10n.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1B1E),
        title: Text(l10n.get('perspective_restart_required'),
            style: TextStyle(color: Colors.white)),
        content: Text(
          l10n.get('perspective_restart_message'),
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.get('ok'), style: const TextStyle(color: Color(0xFF56E39F))),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(String text) {
    final l10n = AppL10n.of(context);
    final hasArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(text);
    final displayText = text.isEmpty ? l10n.get('perspective_no_text_detected') : text;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1B1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.text_snippet_rounded,
                        color: Color(0xFF56E39F)),
                    const SizedBox(width: 12),
                    Text(
                      l10n.get('perspective_text_sheet_title'),
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon:
                          const Icon(Icons.copy_rounded, color: Colors.white70),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(l10n.get('perspective_text_copied'))),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white10, height: 32),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: SingleChildScrollView(
                      child: Directionality(
                        textDirection:
                            hasArabic ? TextDirection.rtl : TextDirection.ltr,
                        child: SelectableText(
                          displayText,
                          textAlign:
                              hasArabic ? TextAlign.right : TextAlign.left,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewControls(AppL10n l10n) {
    return Container(
      color: const Color(0xFF131417),
      padding: const EdgeInsets.only(bottom: 32, top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomAction(
            icon: Icons.close_rounded,
            label: l10n.get('perspective_discard'),
            onTap: () => setState(() => _showPreview = false),
          ),
          _BottomAction(
            icon: Icons.text_fields_rounded,
            label: l10n.get('perspective_extract_text'),
            onTap: _extractText,
          ),
          _BottomAction(
            icon: Icons.done_all_rounded,
            label: l10n.get('perspective_done'),
            highlight: true,
            onTap: _onConfirmSave,
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlight;

  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = highlight ? const Color(0xFF56E39F) : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}





