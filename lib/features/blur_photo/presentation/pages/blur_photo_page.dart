import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/widgets/result_preview_screen.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

import '../../data/datasources/bp_segmentation_datasource.dart';
import '../../data/rendering/bp_isolate_renderer.dart';
import '../../data/repositories/bp_blur_repository_impl.dart';
import '../../domain/entities/blur_mode.dart';
import '../../domain/entities/blur_style.dart';
import '../../domain/entities/blur_settings.dart';
import '../../domain/entities/circle_params.dart';
import '../../domain/entities/line_params.dart';
import '../cubit/blur_photo_cubit.dart';
import '../cubit/blur_photo_state.dart';
import '../widgets/bp_canvas_view.dart';
import '../widgets/bp_intensity_slider.dart';
import '../widgets/bp_mode_bar.dart';
import '../widgets/bp_top_bar.dart';

const _kBg = Color(0xFF0B0B0D);
const _kAccent = Color(0xFF56E39F);

class BlurPhotoPage extends StatelessWidget {
  const BlurPhotoPage({
    super.key,
    required this.initialImage,
    this.onApply,
    this.onClose,
  });

  final ui.Image initialImage;
  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BlurPhotoCubit>(
      create: (_) => BlurPhotoCubit(
        repository: BpBlurRepositoryImpl(
          renderer: const BpIsolateRenderer(),
          segmentation: BpSegmentationDatasource(),
        ),
      )..initialize(initialImage),
      child: _BlurPhotoView(onApply: onApply, onClose: onClose),
    );
  }
}

class _BlurPhotoView extends StatelessWidget {
  const _BlurPhotoView({this.onApply, this.onClose});

  final ValueChanged<Uint8List>? onApply;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<BlurPhotoCubit, BlurPhotoState>(
          listenWhen: (p, c) => p.errorMessage != c.errorMessage,
          listener: (context, state) {
            final msg = state.errorMessage;
            if (msg != null && msg.isNotEmpty) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }
          },
          builder: (context, state) {
            final cubit = context.read<BlurPhotoCubit>();

            if (state.status == BpEditorStatus.loading ||
                state.originalImage == null) {
              return const Center(
                child: CircularProgressIndicator(color: _kAccent),
              );
            }

            final visibleImage = state.showOriginal
                ? state.originalImage!
                : (state.previewImage ?? state.originalImage!);

            return Column(
              children: [
                BpTopBar(
                  status: state.status,
                  onClose: () {
                    onClose?.call();
                    Navigator.of(context).pop();
                  },
                  onExport: () async {
                    final bytes = await cubit.exportFinal();
                    if (!context.mounted || bytes == null) return;

                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => ResultPreviewScreen(
                          title: l10n.get('blur_photo_result'),
                          resultBytes: bytes,
                          onDone: onApply == null ? null : () => onApply!(bytes),
                        ),
                      ),
                    );
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                    child: Stack(
                      children: [
                        BpCanvasView(
                          image: visibleImage,
                          settings: state.settings,
                          onCircleUpdate: (p) => cubit.updateCircle(
                            p as CircleBlurParams,
                            trackOnly: true,
                          ),
                          onCircleEnd: (p) => cubit.commitCircleInteractionEnd(
                            p as CircleBlurParams,
                          ),
                          onLineUpdate: (p) => cubit.updateLine(
                            p as LineBlurParams,
                            trackOnly: true,
                          ),
                          onLineEnd: (p) => cubit.commitLineInteractionEnd(
                            p as LineBlurParams,
                          ),
                        ),
                        if (state.isBusy)
                          const Positioned(
                            top: 12,
                            right: 12,
                            child: _BusyIndicator(),
                          ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(maxHeight: 290),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1013),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              _ActionButton(
                                icon: Icons.undo_rounded,
                                label: 'Undo',
                                enabled: state.canUndo,
                                onTap:
                                    state.canUndo ? () => cubit.undo() : null,
                              ),
                              _ActionButton(
                                icon: Icons.redo_rounded,
                                label: 'Redo',
                                enabled: state.canRedo,
                                onTap:
                                    state.canRedo ? () => cubit.redo() : null,
                              ),
                              _HoldCompareButton(
                                onHoldStart: cubit.showOriginal,
                              ),
                              _StyleMenuButton(
                                activeStyle: state.settings.style,
                                onSelected: (style) => cubit.updateStyle(style),
                              ),
                              if (_showsShapeMenu(state.activeMode))
                                _ShapeMenuButton(
                                  activePreset:
                                      _activePresetFor(state.settings),
                                  onSelected: (preset) =>
                                      _applyPreset(cubit, preset),
                                ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 6, 0, 0),
                          child: BpIntensitySlider(
                            value: state.settings.blurIntensity,
                            onChanged: cubit.updateIntensity,
                            onChangeEnd: cubit.onIntensityDragEnd,
                          ),
                        ),
                        if (state.hintMessage != null &&
                            state.hintMessage!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                state.hintMessage!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 12,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        BpModeBar(
                          activeMode: state.activeMode,
                          onChanged: (mode) => cubit.setMode(mode),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BusyIndicator extends StatelessWidget {
  const _BusyIndicator();

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 13,
            height: 13,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _kAccent,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.get('blur_photo_processing'),
            style: const TextStyle(color: Colors.white, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? _kAccent : Colors.white.withValues(alpha: 0.28);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? 0.05 : 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoldCompareButton extends StatelessWidget {
  const _HoldCompareButton({required this.onHoldStart});

  final ValueChanged<bool> onHoldStart;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => onHoldStart(true),
      onTapUp: (_) => onHoldStart(false),
      onTapCancel: () => onHoldStart(false),
      onPanEnd: (_) => onHoldStart(false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.compare_rounded, size: 17, color: _kAccent),
            const SizedBox(width: 6),
            Text(
              l10n.get('blur_photo_compare'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyleMenuButton extends StatelessWidget {
  const _StyleMenuButton({
    required this.activeStyle,
    required this.onSelected,
  });

  final BlurPhotoStyle activeStyle;
  final ValueChanged<BlurPhotoStyle> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return PopupMenuButton<BlurPhotoStyle>(
      tooltip: l10n.get('blur_photo_style'),
      color: const Color(0xFF15171B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: onSelected,
      itemBuilder: (context) => BlurPhotoStyle.values
          .map(
            (style) => PopupMenuItem<BlurPhotoStyle>(
              value: style,
              child: _PopupOptionRow(
                icon: _styleIcon(style),
                title: _styleLabel(l10n, style),
                subtitle: _styleDescription(l10n, style),
                active: activeStyle == style,
              ),
            ),
          )
          .toList(),
      child: _MenuChip(
        icon: Icons.layers_outlined,
        label: l10n.get('blur_photo_style'),
        detail: _styleLabel(l10n, activeStyle),
      ),
    );
  }
}

class _ShapeMenuButton extends StatelessWidget {
  const _ShapeMenuButton({
    required this.activePreset,
    required this.onSelected,
  });

  final _ShapePreset activePreset;
  final ValueChanged<_ShapePreset> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return PopupMenuButton<_ShapePreset>(
      tooltip: l10n.get('blur_photo_shape'),
      color: const Color(0xFF15171B),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      onSelected: onSelected,
      itemBuilder: (context) => _shapePresets
          .map(
            (preset) => PopupMenuItem<_ShapePreset>(
              value: preset.preset,
              child: _PopupOptionRow(
                icon: preset.icon,
                title: _shapeLabel(l10n, preset.preset),
                subtitle: _shapeDescription(l10n, preset.preset),
                active: activePreset == preset.preset,
              ),
            ),
          )
          .toList(),
      child: _MenuChip(
        icon: Icons.category_outlined,
        label: l10n.get('blur_photo_shape'),
        detail: _shapeLabel(l10n, activePreset),
      ),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: _kAccent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            detail,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.48),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupOptionRow extends StatelessWidget {
  const _PopupOptionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? _kAccent : Colors.white.withValues(alpha: 0.84);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.46),
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

void _applyPreset(BlurPhotoCubit cubit, _ShapePreset preset) {
  switch (preset) {
    case _ShapePreset.circle:
      cubit.setMode(BlurPhotoMode.circle);
      cubit.commitCircleInteractionEnd(
        const CircleBlurParams(
          radiusX: 0.24,
          radiusY: 0.24,
          feather: 0.18,
          shapeType: BlurShapeType.ellipse,
        ),
      );
      break;
    case _ShapePreset.oval:
      cubit.setMode(BlurPhotoMode.circle);
      cubit.commitCircleInteractionEnd(
        const CircleBlurParams(
          radiusX: 0.30,
          radiusY: 0.20,
          feather: 0.16,
          shapeType: BlurShapeType.ellipse,
        ),
      );
      break;
    case _ShapePreset.portrait:
      cubit.setMode(BlurPhotoMode.circle);
      cubit.commitCircleInteractionEnd(
        const CircleBlurParams(
          centerY: 0.46,
          radiusX: 0.22,
          radiusY: 0.32,
          feather: 0.22,
          shapeType: BlurShapeType.ellipse,
        ),
      );
      break;
    case _ShapePreset.rectangle:
      cubit.setMode(BlurPhotoMode.circle);
      cubit.commitCircleInteractionEnd(
        const CircleBlurParams(
          radiusX: 0.28,
          radiusY: 0.18,
          feather: 0.14,
          shapeType: BlurShapeType.rectangle,
        ),
      );
      break;
    case _ShapePreset.tilt:
      cubit.setMode(BlurPhotoMode.line);
      cubit.commitLineInteractionEnd(
        const LineBlurParams(bandWidth: 0.18, feather: 0.16),
      );
      break;
    case _ShapePreset.vertical:
      cubit.setMode(BlurPhotoMode.line);
      cubit.commitLineInteractionEnd(
        const LineBlurParams(
          angle: 1.57079632679,
          bandWidth: 0.16,
          feather: 0.18,
        ),
      );
      break;
    case _ShapePreset.diagonal:
      cubit.setMode(BlurPhotoMode.line);
      cubit.commitLineInteractionEnd(
        const LineBlurParams(
          angle: 0.78,
          bandWidth: 0.15,
          feather: 0.20,
        ),
      );
      break;
  }
}

bool _showsShapeMenu(BlurPhotoMode mode) =>
    mode == BlurPhotoMode.circle || mode == BlurPhotoMode.line;

_ShapePreset _activePresetFor(BlurPhotoSettings settings) {
  if (settings.mode == BlurPhotoMode.line) {
    final angle = settings.line.angle.abs();
    if ((angle - 1.57079632679).abs() < 0.30) return _ShapePreset.vertical;
    if ((angle - 0.78).abs() < 0.30) return _ShapePreset.diagonal;
    return _ShapePreset.tilt;
  }

  final params = settings.circle;
  if (params.shapeType == BlurShapeType.rectangle) {
    return _ShapePreset.rectangle;
  }
  final tall = params.radiusY > params.radiusX * 1.2;
  final wide = params.radiusX > params.radiusY * 1.2;
  if (tall) return _ShapePreset.portrait;
  if (wide) return _ShapePreset.oval;
  return _ShapePreset.circle;
}

String _shapeLabel(AppL10n l10n, _ShapePreset preset) => switch (preset) {
      _ShapePreset.circle => l10n.get('blur_shape_circle'),
      _ShapePreset.oval => l10n.get('blur_shape_oval'),
      _ShapePreset.portrait => l10n.get('blur_shape_portrait'),
      _ShapePreset.rectangle => l10n.get('blur_shape_rectangle'),
      _ShapePreset.tilt => l10n.get('blur_shape_tilt'),
      _ShapePreset.vertical => l10n.get('blur_shape_vertical'),
      _ShapePreset.diagonal => l10n.get('blur_shape_diagonal'),
    };

String _shapeDescription(AppL10n l10n, _ShapePreset preset) => switch (preset) {
      _ShapePreset.circle => l10n.get('blur_shape_circle_desc'),
      _ShapePreset.oval => l10n.get('blur_shape_oval_desc'),
      _ShapePreset.portrait => l10n.get('blur_shape_portrait_desc'),
      _ShapePreset.rectangle => l10n.get('blur_shape_rectangle_desc'),
      _ShapePreset.tilt => l10n.get('blur_shape_tilt_desc'),
      _ShapePreset.vertical => l10n.get('blur_shape_vertical_desc'),
      _ShapePreset.diagonal => l10n.get('blur_shape_diagonal_desc'),
    };

String _styleLabel(AppL10n l10n, BlurPhotoStyle style) => switch (style) {
      BlurPhotoStyle.soft => l10n.get('blur_style_soft'),
      BlurPhotoStyle.frost => l10n.get('blur_style_frost'),
      BlurPhotoStyle.motion => l10n.get('blur_style_motion'),
      BlurPhotoStyle.crystal => l10n.get('blur_style_crystal'),
      BlurPhotoStyle.spotlight => l10n.get('blur_style_spotlight'),
    };

String _styleDescription(AppL10n l10n, BlurPhotoStyle style) => switch (style) {
      BlurPhotoStyle.soft => l10n.get('blur_style_soft_desc'),
      BlurPhotoStyle.frost => l10n.get('blur_style_frost_desc'),
      BlurPhotoStyle.motion => l10n.get('blur_style_motion_desc'),
      BlurPhotoStyle.crystal => l10n.get('blur_style_crystal_desc'),
      BlurPhotoStyle.spotlight => l10n.get('blur_style_spotlight_desc'),
    };

IconData _styleIcon(BlurPhotoStyle style) => switch (style) {
      BlurPhotoStyle.soft => Icons.blur_on_rounded,
      BlurPhotoStyle.frost => Icons.ac_unit_rounded,
      BlurPhotoStyle.motion => Icons.motion_photos_on_rounded,
      BlurPhotoStyle.crystal => Icons.diamond_outlined,
      BlurPhotoStyle.spotlight => Icons.highlight_alt_rounded,
    };

enum _ShapePreset {
  circle,
  oval,
  portrait,
  rectangle,
  tilt,
  vertical,
  diagonal,
}

class _ShapePresetOption {
  const _ShapePresetOption({
    required this.preset,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final _ShapePreset preset;
  final String label;
  final String subtitle;
  final IconData icon;
}

const _shapePresets = <_ShapePresetOption>[
  _ShapePresetOption(
    preset: _ShapePreset.circle,
    label: '',
    subtitle: '',
    icon: Icons.circle_outlined,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.oval,
    label: '',
    subtitle: '',
    icon: Icons.egg_alt_outlined,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.portrait,
    label: '',
    subtitle: '',
    icon: Icons.person_outline_rounded,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.rectangle,
    label: '',
    subtitle: '',
    icon: Icons.crop_square_rounded,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.tilt,
    label: '',
    subtitle: '',
    icon: Icons.view_stream_outlined,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.vertical,
    label: '',
    subtitle: '',
    icon: Icons.splitscreen_outlined,
  ),
  _ShapePresetOption(
    preset: _ShapePreset.diagonal,
    label: '',
    subtitle: '',
    icon: Icons.show_chart_rounded,
  ),
];











