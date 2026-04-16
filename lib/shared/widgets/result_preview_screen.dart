import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

class ResultPreviewScreen extends StatefulWidget {
  const ResultPreviewScreen({
    super.key,
    required this.title,
    required this.resultBytes,
    this.onDone,
  });

  final String title;
  final Uint8List resultBytes;
  final VoidCallback? onDone;

  @override
  State<ResultPreviewScreen> createState() => _ResultPreviewScreenState();
}

class _ResultPreviewScreenState extends State<ResultPreviewScreen> {
  bool _isSaving = false;
  bool _isSharing = false;
  bool _saved = false;

  Future<void> _saveResult() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);
    try {
      await Gal.putImageBytes(widget.resultBytes, name: _fileName);
      if (!mounted) return;
      setState(() => _saved = true);
      _showSnack(
        'تم حفظ الصورة في المعرض',
        backgroundColor: const Color(0xFF1C7C54),
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'تعذر حفظ الصورة: $error',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _shareResult() async {
    if (_isSharing) return;

    setState(() => _isSharing = true);
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            widget.resultBytes,
            mimeType: 'image/png',
            name: '$_fileName.png',
          ),
        ],
        text: widget.title,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack(
        'تعذرت مشاركة الصورة: $error',
        backgroundColor: Colors.redAccent,
      );
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  String get _fileName =>
      '${widget.title.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}';

  void _showSnack(String message, {required Color backgroundColor}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
      ),
    );
  }

  void _finish() {
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF08090B),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0A0B0E), Color(0xFF11151A), Color(0xFF0C0F13)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              children: [
                Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: _finish,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: const Text(
                        'RESULT',
                        style: TextStyle(
                          color: Color(0xFF56E39F),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'معاينة نهائية جاهزة للحفظ أو المشاركة مباشرة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _InfoChip(
                        icon: Icons.high_quality_rounded,
                        label: 'جودة عالية',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _InfoChip(
                        icon: _saved
                            ? Icons.check_circle_rounded
                            : Icons.auto_awesome_rounded,
                        label: _saved ? 'تم الحفظ' : 'جاهزة للتصدير',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white10),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF56E39F).withValues(alpha: 0.08),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Container(color: const Color(0xFF15181D)),
                          Image.memory(
                            widget.resultBytes,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSharing ? null : _shareResult,
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          side: const BorderSide(color: Colors.white24),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.ios_share_rounded),
                        label: const Text('مشاركة'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveResult,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(56),
                          backgroundColor: const Color(0xFF56E39F),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : Icon(
                                _saved
                                    ? Icons.check_circle_rounded
                                    : Icons.download_rounded,
                              ),
                        label: Text(_saved ? 'تم الحفظ' : 'حفظ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF56E39F), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
