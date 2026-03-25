import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'context_panels.dart';
import 'editor_scope.dart';
import 'unified_editor_workspace.dart';

/// Pro mode: HSL + Curves + Multi-sample in one refined surface (progressive tabs).
class ProRefinePanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const ProRefinePanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<ProRefinePanel> createState() => _ProRefinePanelState();
}

class _ProRefinePanelState extends State<ProRefinePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // HSL (UI state; wire to engine when integrating)
  double _hueShift = 0;
  double _saturation = 0;
  double _luminance = 0;

  // Curves (shadows / midtones / highlights shaping)
  double _curveShadows = 0.5;
  double _curveMids = 0.5;
  double _curveHighlights = 0.5;
  double _curveOverall = 0.5;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppTokens.card.withValues(alpha: 0.35),
          child: TabBar(
            controller: _tabs,
            indicatorColor: AppTokens.primary,
            labelColor: AppTokens.primary,
            unselectedLabelColor: AppTokens.text2,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
            tabs: const [
              Tab(text: 'HSL'),
              Tab(text: 'Curves'),
              Tab(text: 'Samples'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: [
              _HslTab(
                hueShift: _hueShift,
                saturation: _saturation,
                luminance: _luminance,
                onHue: (v) => setState(() => _hueShift = v),
                onSat: (v) => setState(() => _saturation = v),
                onLum: (v) => setState(() => _luminance = v),
              ),
              _CurvesTab(
                shadows: _curveShadows,
                mids: _curveMids,
                highlights: _curveHighlights,
                overall: _curveOverall,
                onShadows: (v) => setState(() => _curveShadows = v),
                onMids: (v) => setState(() => _curveMids = v),
                onHighlights: (v) => setState(() => _curveHighlights = v),
                onOverall: (v) => setState(() => _curveOverall = v),
              ),
              MultiSamplePanel(
                status: widget.status,
                mode: widget.mode,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HslTab extends StatelessWidget {
  final double hueShift;
  final double saturation;
  final double luminance;
  final ValueChanged<double> onHue;
  final ValueChanged<double> onSat;
  final ValueChanged<double> onLum;

  const _HslTab({
    required this.hueShift,
    required this.saturation,
    required this.luminance,
    required this.onHue,
    required this.onSat,
    required this.onLum,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HSL',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hue / saturation / lightness for pro color work. Connect sliders to your grading pipeline when ready.',
            style: TextStyle(
              color: AppTokens.text2,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _slider(
            'Hue shift',
            hueShift,
            -0.5,
            0.5,
            onHue,
            (v) => '${(v * 180).toStringAsFixed(0)}°',
          ),
          _slider(
            'Saturation',
            saturation,
            -1,
            1,
            onSat,
            (v) => v >= 0 ? '+${(v * 100).round()}%' : '${(v * 100).round()}%',
          ),
          _slider(
            'Lightness',
            luminance,
            -1,
            1,
            onLum,
            (v) => v >= 0 ? '+${(v * 100).round()}%' : '${(v * 100).round()}%',
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              EditorScope.maybeOf(context)?.setProColor(
                hueShift: hueShift,
                satMul: saturation,
                lumMul: luminance,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('HSL sent to preview pipeline')),
              );
            },
            icon: const Icon(Icons.check_rounded, size: 18),
            label: const Text('Apply HSL'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTokens.primary,
              side: BorderSide(color: AppTokens.primary.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
    String Function(double) fmt,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTokens.text2,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                fmt(value),
                style: const TextStyle(
                  color: AppTokens.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(trackHeight: 3),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurvesTab extends StatelessWidget {
  final double shadows;
  final double mids;
  final double highlights;
  final double overall;
  final ValueChanged<double> onShadows;
  final ValueChanged<double> onMids;
  final ValueChanged<double> onHighlights;
  final ValueChanged<double> onOverall;

  const _CurvesTab({
    required this.shadows,
    required this.mids,
    required this.highlights,
    required this.overall,
    required this.onShadows,
    required this.onMids,
    required this.onHighlights,
    required this.onOverall,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Curves',
            style: TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w900,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Parametric curve controls (shadows / mids / highlights). Map to a real curve LUT or shader in your engine.',
            style: TextStyle(
              color: AppTokens.text2,
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          _curveSlider('Shadows', shadows, onShadows),
          _curveSlider('Midtones', mids, onMids),
          _curveSlider('Highlights', highlights, onHighlights),
          _curveSlider('Master', overall, onOverall),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              EditorScope.maybeOf(context)?.setProColor(
                curveShadow: shadows,
                curveMid: mids,
                curveHi: highlights,
                curveMaster: overall,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Curve shaping sent to preview')),
              );
            },
            icon: const Icon(Icons.timeline_rounded, size: 18),
            label: const Text('Apply curves'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTokens.primary,
              side: BorderSide(color: AppTokens.primary.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _curveSlider(String label, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppTokens.text2,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}',
                style: const TextStyle(
                  color: AppTokens.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: const SliderThemeData(trackHeight: 3),
            child: Slider(
              value: value.clamp(0, 1),
              min: 0,
              max: 1,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
