import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/AppL10n.dart';
import '../../../../core/routing/app_routes.dart';
import '../../application/image_pick_cubit.dart';
import '../widgets/inpainting_studio_chrome.dart';

class HomePickPage extends StatefulWidget {
  const HomePickPage({super.key});

  @override
  State<HomePickPage> createState() => _HomePickPageState();
}

class _HomePickPageState extends State<HomePickPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);

    return Scaffold(
      backgroundColor: InpaintingStudioTheme.background,
      body: BlocConsumer<ImagePickCubit, ImagePickState>(
        listener: (context, state) {
          if (state is ImagePickReady) {
            context.push(AppRoutes.editor);
          }
          if (state is ImagePickError) {
            _showErrorToast(context, state.message);
          }
        },
        builder: (context, state) {
          final isLoading = state is ImagePickLoading;

          return StudioGlowBackground(
            animation: _glowController,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final sidePadding = constraints.maxWidth < 420 ? 16.0 : 24.0;

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          sidePadding,
                          12,
                          sidePadding,
                          28,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1180),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTopBar(context, l10n),
                                SizedBox(height: 24),
                                isWide
                                    ? Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 6,
                                            child: _buildHeroCard(
                                              context,
                                              l10n,
                                              isLoading,
                                            ),
                                          ),
                                          SizedBox(width: 20),
                                          Expanded(
                                            flex: 4,
                                            child: _buildHeroVisual(l10n),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        children: [
                                          _buildHeroCard(
                                            context,
                                            l10n,
                                            isLoading,
                                          ),
                                          SizedBox(height: 18),
                                          _buildHeroVisual(l10n),
                                        ],
                                      ),
                                SizedBox(height: 22),
                                _buildWorkflowStrip(l10n),
                                SizedBox(height: 22),
                                Wrap(
                                  spacing: 14,
                                  runSpacing: 14,
                                  children: [
                                    _buildFeatureCard(
                                      icon: Icons.gesture_rounded,
                                      accent: InpaintingStudioTheme.mint,
                                      title:
                                          l10n.get('magic_pick_feature_precision'),
                                      body: l10n.get('editor_tip_precision'),
                                    ),
                                    _buildFeatureCard(
                                      icon: Icons.flash_on_rounded,
                                      accent: InpaintingStudioTheme.cyan,
                                      title: l10n.get('magic_pick_feature_speed'),
                                      body: l10n.get('magic_pick_feature_quality'),
                                    ),
                                    _buildFeatureCard(
                                      icon: Icons.shield_outlined,
                                      accent: InpaintingStudioTheme.amber,
                                      title: l10n.get('studio_quality'),
                                      body: l10n.get('magic_desc'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isLoading) _buildLoadingOverlay(),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, AppL10n l10n) {
    return StudioGlassPanel(
      radius: 24,
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Row(
        children: [
          _GlassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.home);
              }
            },
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.get('magic_title'),
                  style: TextStyle(
                    color: InpaintingStudioTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  l10n.get('magic_desc'),
                  style: TextStyle(
                    color: InpaintingStudioTheme.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          StudioPill(
            icon: Icons.auto_fix_high_rounded,
            label: l10n.get('control_center'),
            accent: InpaintingStudioTheme.violet,
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, AppL10n l10n, bool isLoading) {
    final picker = context.read<ImagePickCubit>();

    return StudioGlassPanel(
      radius: 34,
      padding: EdgeInsets.all(28),
      gradient: InpaintingStudioTheme.heroGradient,
      borderColor: InpaintingStudioTheme.violet.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              StudioPill(
                icon: Icons.auto_awesome_rounded,
                label: l10n.get('magic_pick_feature_quality'),
                accent: InpaintingStudioTheme.mint,
                filled: true,
              ),
              StudioPill(
                icon: Icons.tune_rounded,
                label: l10n.get('magic_pick_feature_precision'),
                accent: InpaintingStudioTheme.cyan,
              ),
            ],
          ),
          SizedBox(height: 22),
          Text(
            l10n.get('magic_pick_headline'),
            style: TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontSize: 34,
              height: 1.08,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 14),
          Text(
            l10n.get('magic_pick_body'),
            style: TextStyle(
              color: InpaintingStudioTheme.textSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          SizedBox(height: 22),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StudioStatTile(
                label: l10n.get('stat_mask'),
                value: l10n.get('stat_mask_value'),
                accent: InpaintingStudioTheme.cyan,
              ),
              StudioStatTile(
                label: l10n.get('stat_output'),
                value: l10n.get('stat_output_value'),
                accent: InpaintingStudioTheme.mint,
              ),
              StudioStatTile(
                label: l10n.get('processing'),
                value: l10n.get('magic_pick_feature_speed'),
                accent: InpaintingStudioTheme.amber,
              ),
            ],
          ),
          SizedBox(height: 26),
          Row(
            children: [
              Expanded(
                child: StudioPrimaryButton(
                  onPressed: isLoading ? null : picker.pickFromGallery,
                  icon: Icons.photo_library_rounded,
                  label: l10n.get('pick_gallery'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StudioSecondaryButton(
                  onPressed: isLoading ? null : picker.pickFromCamera,
                  icon: Icons.camera_alt_rounded,
                  label: l10n.get('pick_camera'),
                  accent: InpaintingStudioTheme.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroVisual(AppL10n l10n) {
    return StudioGlassPanel(
      radius: 34,
      padding: EdgeInsets.all(20),
      fillColor: InpaintingStudioTheme.surfaceSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.layers_rounded,
                color: InpaintingStudioTheme.mint,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                l10n.get('compare_live'),
                style: TextStyle(
                  color: InpaintingStudioTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: InpaintingStudioTheme.glassDecoration(
                radius: 28,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    InpaintingStudioTheme.surfaceStrong,
                    InpaintingStudioTheme.surface.withValues(alpha: 0.96),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            InpaintingStudioTheme.violet
                                .withValues(alpha: 0.18),
                            Colors.transparent,
                            InpaintingStudioTheme.mint.withValues(alpha: 0.14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    top: 22,
                    start: 22,
                    child: _buildPreviewBadge(
                      icon: Icons.photo_rounded,
                      label: l10n.get('workflow_upload'),
                    ),
                  ),
                  PositionedDirectional(
                    top: 90,
                    end: 22,
                    child: _buildPreviewBadge(
                      icon: Icons.brush_rounded,
                      label: l10n.get('workflow_mask'),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: 22,
                    start: 22,
                    child: _buildPreviewBadge(
                      icon: Icons.auto_fix_high_rounded,
                      label: l10n.get('workflow_render'),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: _PreviewFrame(),
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

  Widget _buildPreviewBadge({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: InpaintingStudioTheme.textPrimary),
          SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: InpaintingStudioTheme.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkflowStrip(AppL10n l10n) {
    final items = [
      (
        step: '01',
        title: l10n.get('workflow_upload'),
        body: l10n.get('pick_hint'),
        accent: InpaintingStudioTheme.cyan,
      ),
      (
        step: '02',
        title: l10n.get('workflow_mask'),
        body: l10n.get('editor_tip_precision'),
        accent: InpaintingStudioTheme.violet,
      ),
      (
        step: '03',
        title: l10n.get('workflow_render'),
        body: l10n.get('magic_pick_feature_quality'),
        accent: InpaintingStudioTheme.mint,
      ),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 14,
      children: items
          .map(
            (item) => SizedBox(
              width: 260,
              child: StudioGlassPanel(
                radius: 26,
                padding: EdgeInsets.all(18),
                fillColor: InpaintingStudioTheme.surfaceSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.step,
                      style: TextStyle(
                        color: item.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: InpaintingStudioTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: InpaintingStudioTheme.textSecondary,
                        fontSize: 13,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color accent,
    required String title,
    required String body,
  }) {
    return SizedBox(
      width: 320,
      child: StudioGlassPanel(
        radius: 26,
        padding: EdgeInsets.all(18),
        fillColor: InpaintingStudioTheme.surfaceSoft,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: InpaintingStudioTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
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
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: InpaintingStudioTheme.background.withValues(alpha: 0.48),
            ),
            child: Center(
              child: StudioGlassPanel(
                radius: 999,
                padding: EdgeInsets.all(26),
                gradient: InpaintingStudioTheme.accentGradient,
                borderColor: Colors.transparent,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showErrorToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: InpaintingStudioTheme.danger.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.all(20),
      ),
    );
  }
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
        child: Icon(
          icon,
          size: 18,
          color: InpaintingStudioTheme.textPrimary,
        ),
      ),
    );
  }
}

class _PreviewFrame extends StatelessWidget {
  const _PreviewFrame();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: AspectRatio(
        aspectRatio: 0.76,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.18),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 20,
              start: 20,
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: InpaintingStudioTheme.cyan.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            PositionedDirectional(
              bottom: 32,
              end: 20,
              child: Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: InpaintingStudioTheme.mint.withValues(alpha: 0.22),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 118,
                  height: 168,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF243A46),
                        Color(0xFF112530),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 60,
              start: 50,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: InpaintingStudioTheme.rose.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
