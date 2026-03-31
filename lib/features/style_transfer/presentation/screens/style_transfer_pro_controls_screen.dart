import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/features/style_transfer/application/style_transfer_controller.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/presentation/widgets/style_slider_tile.dart';
import 'package:untitled2/shared/ui_tokens/viral_studio_tokens.dart';

class StyleTransferProControlsScreen extends StatelessWidget {
  const StyleTransferProControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StyleTransferController>();
    return Scaffold(
      backgroundColor: ViralStudioTokens.background,
      appBar: AppBar(
        backgroundColor: ViralStudioTokens.background,
        foregroundColor: Colors.white,
        title: const Text('Pro Controls'),
      ),
      body: BlocBuilder<StyleTransferController, StyleTransferState>(
        builder: (context, state) {
          final tone = state.settings.toneAdjustment;
          final detail = state.settings.detailAdjustment;
          final local = state.settings.localOverrides;
          return ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
            children: <Widget>[
              Text('Tone', style: ViralStudioTokens.sectionTitle()),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Exposure',
                  value: tone.exposure,
                  min: -0.4,
                  max: 0.4,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(exposure: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Contrast',
                  value: tone.contrast,
                  min: -0.4,
                  max: 0.4,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(contrast: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Highlights',
                  value: tone.highlights,
                  min: -0.4,
                  max: 0.4,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(highlights: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Shadows',
                  value: tone.shadows,
                  min: -0.4,
                  max: 0.4,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(shadows: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Blacks',
                  value: tone.blacks,
                  min: -0.3,
                  max: 0.3,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(blacks: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Whites',
                  value: tone.whites,
                  min: -0.3,
                  max: 0.3,
                  onChanged: (value) => controller.updateTone(
                      (current) => current.copyWith(whites: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Fade',
                  value: tone.fade,
                  min: -0.2,
                  max: 0.4,
                  onChanged: (value) => controller
                      .updateTone((current) => current.copyWith(fade: value))),
              const SizedBox(height: 24),
              Text('HSL', style: ViralStudioTokens.sectionTitle()),
              const SizedBox(height: 12),
              ...<String>[
                'red',
                'orange',
                'yellow',
                'green',
                'aqua',
                'blue',
                'purple',
                'magenta'
              ].map(
                (channel) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ChannelPanel(channel: channel),
                ),
              ),
              const SizedBox(height: 24),
              Text('Curves', style: ViralStudioTokens.sectionTitle()),
              const SizedBox(height: 12),
              Text(
                  'Curve sliders are additive deltas on top of the extracted style curve.',
                  style: ViralStudioTokens.body(12)),
              const SizedBox(height: 12),
              ...<String>['master', 'red', 'green', 'blue'].map(
                (curve) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _CurvePanel(curveName: curve),
                ),
              ),
              const SizedBox(height: 24),
              Text('Detail', style: ViralStudioTokens.sectionTitle()),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Sharpness',
                  value: detail.sharpness,
                  min: -0.3,
                  max: 0.4,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(sharpness: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Clarity',
                  value: detail.clarity,
                  min: -0.3,
                  max: 0.4,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(clarity: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Texture',
                  value: detail.texture,
                  min: -0.3,
                  max: 0.4,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(texture: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Grain',
                  value: detail.grain,
                  min: -0.1,
                  max: 0.3,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(grain: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Vignette',
                  value: detail.vignette,
                  min: -0.2,
                  max: 0.4,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(vignette: value))),
              const SizedBox(height: 12),
              StyleSliderTile(
                  label: 'Bloom',
                  value: detail.bloom,
                  min: -0.1,
                  max: 0.4,
                  onChanged: (value) => controller.updateDetail(
                      (current) => current.copyWith(bloom: value))),
              const SizedBox(height: 24),
              Text('Masks', style: ViralStudioTokens.sectionTitle()),
              const SizedBox(height: 12),
              Container(
                decoration: ViralStudioTokens.panelDecoration(),
                child: Column(
                  children: <Widget>[
                    SwitchListTile.adaptive(
                      value: local.skinProtect,
                      onChanged: (value) => controller.updateMaskRules(
                          (current) => current.copyWith(skinProtect: value)),
                      title: const Text('Skin Protect',
                          style: TextStyle(color: Colors.white)),
                    ),
                    SwitchListTile.adaptive(
                      value: local.faceExposureGuard,
                      onChanged: (value) => controller.updateMaskRules(
                          (current) =>
                              current.copyWith(faceExposureGuard: value)),
                      title: const Text('Face Exposure Guard',
                          style: TextStyle(color: Colors.white)),
                    ),
                    SwitchListTile.adaptive(
                      value: local.skyAdjust,
                      onChanged: (value) => controller.updateMaskRules(
                          (current) => current.copyWith(skyAdjust: value)),
                      title: const Text('Sky Adjust',
                          style: TextStyle(color: Colors.white)),
                    ),
                    SwitchListTile.adaptive(
                      value: local.backgroundAdjust,
                      onChanged: (value) => controller.updateMaskRules(
                          (current) =>
                              current.copyWith(backgroundAdjust: value)),
                      title: const Text('Background Adjust',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChannelPanel extends StatelessWidget {
  const _ChannelPanel({required this.channel});

  final String channel;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StyleTransferController>();
    final hsl = context.select<StyleTransferController, HslChannel>(
      (bloc) => bloc.state.settings.hslAdjustment.channelByName(channel),
    );
    return ExpansionTile(
      collapsedBackgroundColor: ViralStudioTokens.surface,
      backgroundColor: ViralStudioTokens.surfaceSoft,
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(channel.toUpperCase(),
          style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15)),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: <Widget>[
        StyleSliderTile(
            label: 'Hue',
            value: hsl.h,
            min: -12,
            max: 12,
            onChanged: (value) => controller.updateHslChannel(
                channel, (current) => current.copyWith(h: value))),
        const SizedBox(height: 10),
        StyleSliderTile(
            label: 'Saturation',
            value: hsl.s,
            min: -0.3,
            max: 0.3,
            onChanged: (value) => controller.updateHslChannel(
                channel, (current) => current.copyWith(s: value))),
        const SizedBox(height: 10),
        StyleSliderTile(
            label: 'Luminance',
            value: hsl.l,
            min: -0.2,
            max: 0.2,
            onChanged: (value) => controller.updateHslChannel(
                channel, (current) => current.copyWith(l: value))),
      ],
    );
  }
}

class _CurvePanel extends StatelessWidget {
  const _CurvePanel({required this.curveName});

  final String curveName;

  @override
  Widget build(BuildContext context) {
    final controller = context.read<StyleTransferController>();
    final curve = context.select<StyleTransferController, List<double>>((bloc) {
      final curves = bloc.state.settings.curveAdjustment;
      switch (curveName) {
        case 'master':
          return curves.master;
        case 'red':
          return curves.red;
        case 'green':
          return curves.green;
        default:
          return curves.blue;
      }
    });
    return ExpansionTile(
      collapsedBackgroundColor: ViralStudioTokens.surface,
      backgroundColor: ViralStudioTokens.surfaceSoft,
      collapsedIconColor: Colors.white,
      iconColor: Colors.white,
      textColor: Colors.white,
      collapsedTextColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('${curveName.toUpperCase()} Curve',
          style: ViralStudioTokens.sectionTitle().copyWith(fontSize: 15)),
      childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      children: <Widget>[
        StyleSliderTile(
            label: 'Shadow Point',
            value: curve[1],
            min: -0.3,
            max: 0.3,
            onChanged: (value) =>
                controller.updateCurvePoint(curveName, 1, value)),
        const SizedBox(height: 10),
        StyleSliderTile(
            label: 'Mid Point',
            value: curve[2],
            min: -0.3,
            max: 0.3,
            onChanged: (value) =>
                controller.updateCurvePoint(curveName, 2, value)),
        const SizedBox(height: 10),
        StyleSliderTile(
            label: 'Highlight Point',
            value: curve[3],
            min: -0.3,
            max: 0.3,
            onChanged: (value) =>
                controller.updateCurvePoint(curveName, 3, value)),
      ],
    );
  }
}
