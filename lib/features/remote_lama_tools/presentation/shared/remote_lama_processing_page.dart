import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/AppL10n.dart';
import '../../../../inpainting/presentation/widgets/inpainting_studio_chrome.dart';
import '../clean_edges/clean_edges_cubit.dart';
import '../heal_region/heal_region_cubit.dart';
import 'shared_heal_clean_page.dart';

class RemoteLamaProcessingPage extends StatefulWidget {
  final SharedToolMode activeMode;
  final Uint8List? imageBytes;

  const RemoteLamaProcessingPage({
    super.key,
    required this.activeMode,
    this.imageBytes,
  });

  @override
  State<RemoteLamaProcessingPage> createState() =>
      _RemoteLamaProcessingPageState();
}

class _RemoteLamaProcessingPageState extends State<RemoteLamaProcessingPage>
    with TickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  late final AnimationController _scannerController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat(reverse: true);

  ui.Image? _decodedUiImage;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _decodeImage(widget.imageBytes!);
    }
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() {
        _decodedUiImage = frame.image;
      });
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    _scannerController.dispose();
    _decodedUiImage?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.activeMode == SharedToolMode.healRegion) {
      return BlocConsumer<HealRegionCubit, HealRegionState>(
        listener: (context, state) {
          if (state is HealRegionSuccess) {
            context.pop(state.resultBytes);
          }
        },
        builder: (context, state) {
          return _buildContent(
            context: context,
            status: _inferStatus(state),
            jobId: _inferJobId(state),
            progress: _inferProgress(state),
            serverMessage: _inferMessage(state),
            onRetry: () =>
                context.pop(), // Pop backward so they can submit again
            onCancel: () => context.pop(),
          );
        },
      );
    } else {
      return BlocConsumer<CleanEdgesCubit, CleanEdgesState>(
        listener: (context, state) {
          if (state is CleanEdgesSuccess) {
            context.pop(state.resultBytes);
          }
        },
        builder: (context, state) {
          return _buildContent(
            context: context,
            status: _inferStatusClean(state),
            jobId: _inferJobIdClean(state),
            progress: _inferProgressClean(state),
            serverMessage: _inferMessageClean(state),
            onRetry: () => context.pop(),
            onCancel: () => context.pop(),
          );
        },
      );
    }
  }

  Widget _buildContent({
    required BuildContext context,
    required _InternalStatus status,
    required String? jobId,
    required double progress,
    required String? serverMessage,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    final l10n = context.read<AppL10n>();
    final isFailed = status == _InternalStatus.failed;
    final isQueued = status == _InternalStatus.queued;
    final activeStep = _stepFromStatus(status);
    final elapsed =
        '--:--'; // Mock for now since we don't have start time in cubit

    if (isFailed) {
      _scannerController.stop();
      _glowController.stop();
    } else {
      if (!_scannerController.isAnimating) {
        _scannerController.repeat(reverse: true);
      }
      if (!_glowController.isAnimating) {
        _glowController.repeat(reverse: true);
      }
    }

    final headline = _getHeadline(status, serverMessage);
    final modeName = widget.activeMode == SharedToolMode.healRegion
        ? l10n.get('heal_region')
        : l10n.get('clean_edges');

    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: StudioGlowBackground(
        animation: _glowController,
        primaryGlow:
            isFailed ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint,
        secondaryGlow: isFailed
            ? InpaintingStudioTheme.danger
            : InpaintingStudioTheme.violet,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 960;
              final padding = constraints.maxWidth < 460 ? 16.0 : 24.0;

              return SingleChildScrollView(
                padding: EdgeInsetsDirectional.fromSTEB(
                  padding,
                  14,
                  padding,
                  24,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTopBar(context, l10n, modeName, status),
                        const SizedBox(height: 22),
                        isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildPreviewCard(
                                      l10n: l10n,
                                      isFailed: isFailed,
                                      isQueued: isQueued,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    flex: 6,
                                    child: _buildStatusCard(
                                      l10n: l10n,
                                      headline: headline,
                                      serverMessage: serverMessage,
                                      progress: progress,
                                      activeStep: activeStep,
                                      elapsed: elapsed,
                                      jobId: jobId,
                                      isFailed: isFailed,
                                      isQueued: isQueued,
                                      onRetry: onRetry,
                                      onCancel: onCancel,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _buildPreviewCard(
                                    l10n: l10n,
                                    isFailed: isFailed,
                                    isQueued: isQueued,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildStatusCard(
                                    l10n: l10n,
                                    headline: headline,
                                    serverMessage: serverMessage,
                                    progress: progress,
                                    activeStep: activeStep,
                                    elapsed: elapsed,
                                    jobId: jobId,
                                    isFailed: isFailed,
                                    isQueued: isQueued,
                                    onRetry: onRetry,
                                    onCancel: onCancel,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppL10n l10n, String modeName,
      _InternalStatus status) {
    return StudioGlassPanel(
      radius: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.close_rounded,
            onTap: () {
              context.pop();
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  modeName,
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.get('processing_body'),
                  style: const TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          StudioPill(
            icon: Icons.memory_rounded,
            label: status.name.toUpperCase(),
            accent: InpaintingStudioTheme.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard({
    required AppL10n l10n,
    required bool isFailed,
    required bool isQueued,
  }) {
    final accent =
        isFailed ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;

    return StudioGlassPanel(
      radius: 34,
      padding: const EdgeInsets.all(20),
      gradient: InpaintingStudioTheme.heroGradient,
      borderColor: accent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StudioSectionLabel(
            title: l10n.get('processing_headline'),
            subtitle: l10n.get('processing_body'),
          ),
          const SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 0.9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_decodedUiImage != null)
                    RawImage(image: _decodedUiImage, fit: BoxFit.cover)
                  else
                    Container(color: InpaintingStudioTheme.surfaceStrong),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.45),
                        ],
                      ),
                    ),
                  ),
                  if (!isFailed)
                    AnimatedBuilder(
                      animation: _scannerController,
                      builder: (context, child) {
                        final top = -80 + (_scannerController.value * 360);
                        return Positioned(
                          top: top,
                          left: 0,
                          right: 0,
                          child: Opacity(
                            opacity: isQueued ? 0.28 : 1,
                            child: Container(
                              height: 72,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    accent.withValues(alpha: 0),
                                    accent.withValues(alpha: 0.28),
                                    accent.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  Center(
                    child: Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withValues(alpha: 0.32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Icon(
                        isFailed
                            ? Icons.error_outline_rounded
                            : Icons.auto_fix_high_rounded,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 16,
                    start: 16,
                    child: StudioPill(
                      icon: Icons.bolt_rounded,
                      label: l10n.get('compare_live'),
                      accent: accent,
                      filled: true,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required AppL10n l10n,
    required String headline,
    required String? serverMessage,
    required double progress,
    required int activeStep,
    required String elapsed,
    required String? jobId,
    required bool isFailed,
    required bool isQueued,
    required VoidCallback onRetry,
    required VoidCallback onCancel,
  }) {
    final accent =
        isFailed ? InpaintingStudioTheme.rose : InpaintingStudioTheme.mint;
    final jobLabel = jobId == null
        ? '...'
        : jobId.substring(0, jobId.length > 8 ? 8 : jobId.length);

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
              StudioStatTile(
                label: l10n.get('elapsed'),
                value: elapsed,
                accent: InpaintingStudioTheme.textPrimary,
              ),
              StudioStatTile(
                label: l10n.get('job_id'),
                value: jobLabel,
                accent: InpaintingStudioTheme.cyan,
              ),
              StudioStatTile(
                label: l10n.get('queue_position'),
                value: '--', // Not mapped in remote lama yet
                accent: InpaintingStudioTheme.amber,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            headline,
            style: const TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            serverMessage?.trim().isNotEmpty == true
                ? serverMessage!.trim()
                : l10n.get('processing_body'),
            style: const TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          _ProgressDial(progress: progress, accent: accent),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          if (isFailed) ...[
            const SizedBox(height: 16),
            _InfoBanner(
              icon: Icons.warning_amber_rounded,
              accent: InpaintingStudioTheme.rose,
              text: serverMessage ?? l10n.get('failed'),
            ),
          ],
          const SizedBox(height: 22),
          _buildTimeline(l10n, activeStep, accent),
          const SizedBox(height: 22),
          if (isFailed)
            StudioPrimaryButton(
              onPressed: onRetry,
              icon: Icons.refresh_rounded,
              label: l10n.get('retry'),
            )
          else
            StudioSecondaryButton(
              onPressed: onCancel,
              icon: Icons.arrow_back_rounded,
              label: l10n.get('return_editor'),
              accent: InpaintingStudioTheme.textPrimary,
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(AppL10n l10n, int activeStep, Color accent) {
    final items = [
      l10n.get('queued'),
      l10n.get('uploading'),
      l10n.get('processing'),
      l10n.get('downloading'),
    ];

    return Column(
      children: List.generate(items.length, (index) {
        final done = index < activeStep;
        final active = index == activeStep;
        final dotColor = done
            ? accent
            : active
                ? accent.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.08);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                  border: Border.all(
                    color: active ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.black)
                    : active
                        ? Center(
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          )
                        : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  items[index],
                  style: TextStyle(
                    color: active || done
                        ? InpaintingStudioTheme.textPrimary
                        : InpaintingStudioTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Helpers to infer standard rendering state from varied Cubits
  _InternalStatus _inferStatus(HealRegionState state) {
    if (state is HealRegionSubmitting) return _InternalStatus.uploading;
    if (state is HealRegionProcessing) {
      if (state.status.status == 'queued') return _InternalStatus.queued;
      return _InternalStatus.processing;
    }
    if (state is HealRegionFailure) return _InternalStatus.failed;
    if (state is HealRegionSuccess) return _InternalStatus.success;
    return _InternalStatus.uploading;
  }

  String? _inferJobId(HealRegionState state) {
    if (state is HealRegionProcessing) return state.status.jobId;
    return null;
  }

  double _inferProgress(HealRegionState state) {
    if (state is HealRegionSubmitting) return 0.1;
    if (state is HealRegionProcessing) {
      return (state.status.progress / 100).clamp(0.1, 0.95);
    }
    if (state is HealRegionSuccess) return 1.0;
    return 0.1;
  }

  String? _inferMessage(HealRegionState state) {
    if (state is HealRegionProcessing) return state.status.message;
    if (state is HealRegionFailure) return state.message;
    return null;
  }

  _InternalStatus _inferStatusClean(CleanEdgesState state) {
    if (state is CleanEdgesSubmitting) return _InternalStatus.uploading;
    if (state is CleanEdgesProcessing) {
      if (state.status.status == 'queued') return _InternalStatus.queued;
      return _InternalStatus.processing;
    }
    if (state is CleanEdgesFailure) return _InternalStatus.failed;
    if (state is CleanEdgesSuccess) return _InternalStatus.success;
    return _InternalStatus.uploading;
  }

  String? _inferJobIdClean(CleanEdgesState state) {
    if (state is CleanEdgesProcessing) return state.status.jobId;
    return null;
  }

  double _inferProgressClean(CleanEdgesState state) {
    if (state is CleanEdgesSubmitting) return 0.1;
    if (state is CleanEdgesProcessing) {
      return (state.status.progress / 100).clamp(0.1, 0.95);
    }
    if (state is CleanEdgesSuccess) return 1.0;
    return 0.1;
  }

  String? _inferMessageClean(CleanEdgesState state) {
    if (state is CleanEdgesProcessing) return state.status.message;
    if (state is CleanEdgesFailure) return state.message;
    return null;
  }

  int _stepFromStatus(_InternalStatus status) {
    switch (status) {
      case _InternalStatus.queued:
        return 0;
      case _InternalStatus.uploading:
        return 1;
      case _InternalStatus.processing:
        return 2;
      case _InternalStatus.downloading:
        return 3;
      case _InternalStatus.success:
        return 4;
      case _InternalStatus.failed:
        return 2;
    }
  }

  String _getHeadline(_InternalStatus status, String? serverMsg) {
    if (serverMsg != null && serverMsg.trim().isNotEmpty) {
      return serverMsg.trim();
    }
    switch (status) {
      case _InternalStatus.queued:
        return 'Queued';
      case _InternalStatus.uploading:
        return 'Uploading';
      case _InternalStatus.processing:
        return 'Processing';
      case _InternalStatus.downloading:
        return 'Downloading';
      case _InternalStatus.failed:
        return 'Failed';
      case _InternalStatus.success:
        return 'Done';
    }
  }
}

enum _InternalStatus {
  queued,
  uploading,
  processing,
  downloading,
  success,
  failed,
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: InpaintingStudioTheme.textPrimary, size: 20),
      ),
    );
  }
}

class _ProgressDial extends StatelessWidget {
  final double progress;
  final Color accent;

  const _ProgressDial({
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final label = '${(progress * 100).round()}%';

    return Center(
      child: SizedBox(
        width: 128,
        height: 128,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 11,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: InpaintingStudioTheme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'AI',
                    style: TextStyle(
                      color: InpaintingStudioTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String text;

  const _InfoBanner({
    required this.icon,
    required this.accent,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: InpaintingStudioTheme.textPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
