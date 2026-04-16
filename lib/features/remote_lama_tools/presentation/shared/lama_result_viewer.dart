import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_compare_slider.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_studio_chrome.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1024;
        final padding = constraints.maxWidth < 460 ? 16.0 : 24.0;

        return SingleChildScrollView(
          padding: EdgeInsetsDirectional.fromSTEB(padding, 14, padding, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _buildCompareCard(),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 5,
                              child: _buildSummaryPanel(context),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildCompareCard(),
                            const SizedBox(height: 18),
                            _buildSummaryPanel(context),
                          ],
                        ),
                  const SizedBox(height: 18),
                  _buildActionDock(context),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompareCard() {
    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(20),
      gradient: InpaintingStudioTheme.heroGradient,
      borderColor: InpaintingStudioTheme.cyan.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StudioSectionLabel(
            title: 'Result Preview',
            subtitle: 'Slide to compare the original and processed image.',
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: originalBytes == null
                  ? Image.memory(resultBytes, fit: BoxFit.contain)
                  : LamaCompareSlider(
                      before: Image.memory(originalBytes!, fit: BoxFit.cover),
                      after: Image.memory(resultBytes, fit: BoxFit.cover),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryPanel(BuildContext context) {
    final fileSizeKb = (resultBytes.length / 1024).toStringAsFixed(0);

    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(24),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              const StudioStatTile(
                label: 'Result',
                value: 'Ready',
                accent: InpaintingStudioTheme.cyan,
              ),
              StudioStatTile(
                label: 'Format',
                value: 'PNG • $fileSizeKb KB',
                accent: InpaintingStudioTheme.mint,
              ),
              const StudioStatTile(
                label: 'Status',
                value: 'Finished',
                accent: InpaintingStudioTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SummaryBlock(
            icon: Icons.compare_arrows_rounded,
            accent: InpaintingStudioTheme.cyan,
            title: 'Compare Live',
            body: 'Interact with the slider to see exact differences.',
          ),
          const SizedBox(height: 14),
          const _SummaryBlock(
            icon: Icons.auto_fix_high_rounded,
            accent: InpaintingStudioTheme.mint,
            title: 'Studio Quality',
            body: 'Exported using precise formatting.',
          ),
          const SizedBox(height: 14),
          const _SummaryBlock(
            icon: Icons.edit_rounded,
            accent: InpaintingStudioTheme.violet,
            title: 'Edit Again',
            body: 'Make adjustments and run again.',
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock(BuildContext context) {
    return StudioGlassPanel(
      radius: 32,
      padding: const EdgeInsets.all(16),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: 180,
            child: StudioSecondaryButton(
              onPressed: onReset,
              icon: Icons.restart_alt_rounded,
              label: 'Start Over',
              accent: InpaintingStudioTheme.textPrimary,
            ),
          ),
          if (onRetry != null)
            SizedBox(
              width: 180,
              child: StudioSecondaryButton(
                onPressed: onRetry!,
                icon: Icons.edit_rounded,
                label: 'Adjust & Retry',
                accent: InpaintingStudioTheme.textPrimary,
              ),
            ),
          SizedBox(
            width: 180,
            child: StudioSecondaryButton(
              onPressed: () => _shareImage(context),
              icon: Icons.ios_share_rounded,
              label: 'Share',
              accent: InpaintingStudioTheme.textPrimary,
            ),
          ),
          SizedBox(
            width: 220,
            child: StudioPrimaryButton(
              onPressed: () => _saveImage(context),
              icon: Icons.download_rounded,
              label: 'Save Result',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBlock extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title;
  final String body;

  const _SummaryBlock({
    required this.icon,
    required this.accent,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
