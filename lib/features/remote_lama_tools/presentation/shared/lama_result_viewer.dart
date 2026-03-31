import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_compare_slider.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class LamaResultViewer extends StatelessWidget {
  final Uint8List resultBytes;
  final Uint8List? originalBytes;
  final VoidCallback onReset;
  final VoidCallback? onRetry;

  const LamaResultViewer({
    super.key,
    required this.resultBytes,
    required this.onReset,
    this.originalBytes,
    this.onRetry,
  });

  Future<void> _saveImage(BuildContext context) async {
    try {
      await Gal.putImageBytes(resultBytes);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved locally successfully!'),
            backgroundColor: LamaTheme.accent,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to gallery: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Future<void> _shareImage(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [
          XFile.fromData(
            resultBytes,
            mimeType: 'image/png',
            name: 'lama_result.png',
          ),
        ],
        text: 'Processed with Remote LaMa Studio',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = originalBytes == null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Image.memory(resultBytes, fit: BoxFit.contain),
          )
        : LamaCompareSlider(
            before: Image.memory(originalBytes!, fit: BoxFit.cover),
            after: Image.memory(resultBytes, fit: BoxFit.cover),
          );

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Result Preview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  originalBytes == null
                      ? 'Preview the generated image and export it when ready.'
                      : 'Drag the slider to compare the original image with the processed result.',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: content,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          color: LamaTheme.toolbarBg,
          padding: const EdgeInsets.all(16),
          child: SafeArea(
            top: false,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Start Over'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                ),
                if (onRetry != null)
                  OutlinedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Adjust & Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: LamaTheme.accent,
                      side: const BorderSide(color: LamaTheme.accent),
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: () => _shareImage(context),
                  icon: const Icon(Icons.share_outlined),
                  label: const Text('Share'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white24),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _saveImage(context),
                  icon: const Icon(Icons.download_rounded, color: Colors.black),
                  label: const Text(
                    'Save Result',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: LamaTheme.accent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
