import 'package:flutter/material.dart';
import 'adjust_params.dart';

class AdjustTabPro extends StatefulWidget {
  final AdjustParams value;
  final ValueChanged<AdjustParams> onChanged;

  final VoidCallback? onCompareHoldStart;
  final VoidCallback? onCompareHoldEnd;

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const AdjustTabPro({
    super.key,
    required this.value,
    required this.onChanged,
    this.onCompareHoldStart,
    this.onCompareHoldEnd,
    this.onUndo,
    this.onRedo,
    this.canUndo = false,
    this.canRedo = false,
  });

  @override
  State<AdjustTabPro> createState() => _AdjustTabProState();
}

class _AdjustTabProState extends State<AdjustTabPro> {
  bool _advanced = false;

  void _apply(AdjustParams next) => widget.onChanged(next);

  void _reset() => _apply(AdjustParams.defaults);

  void _applyPreset(AdjustPreset p) {
    // احتفظ بحالة removeBg الحالية إن أردت
    _apply(p.params.copyWith(removeBg: widget.value.removeBg));
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.value;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 18),
      physics: const BouncingScrollPhysics(),
      children: [
        _HeaderRow(
          advanced: _advanced,
          onToggleAdvanced: () => setState(() => _advanced = !_advanced),
          onReset: _reset,
          onCompareHoldStart: widget.onCompareHoldStart,
          onCompareHoldEnd: widget.onCompareHoldEnd,
          onUndo: widget.onUndo,
          onRedo: widget.onRedo,
          canUndo: widget.canUndo,
          canRedo: widget.canRedo,
        ),
        const SizedBox(height: 10),

        _PresetStrip(presets: kAdjustPresets, onTapPreset: _applyPreset),
        const SizedBox(height: 14),

        _Section('Core'),
        _ProSlider(
          title: 'Exposure',
          value: v.exposure,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(exposure: x)),
        ),
        _ProSlider(
          title: 'Contrast',
          value: v.contrast,
          min: 0.5,
          max: 1.5,
          onChanged: (x) => _apply(v.copyWith(contrast: x)),
        ),
        _ProSlider(
          title: 'Saturation',
          value: v.saturation,
          min: 0.0,
          max: 2.0,
          onChanged: (x) => _apply(v.copyWith(saturation: x)),
        ),
        _ProSlider(
          title: 'Vibrance',
          value: v.vibrance,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(vibrance: x)),
        ),
        _ProSlider(
          title: 'Brightness',
          value: v.brightness,
          min: -0.5,
          max: 0.5,
          onChanged: (x) => _apply(v.copyWith(brightness: x)),
        ),

        _ProSwitch(
          title: 'Remove Background',
          value: v.removeBg,
          onChanged: (b) => _apply(v.copyWith(removeBg: b)),
        ),

        const SizedBox(height: 14),
        _Section('Tone'),
        _ProSlider(
          title: 'Warmth',
          value: v.warmth,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(warmth: x)),
        ),
        _ProSlider(
          title: 'Tint',
          value: v.tint,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(tint: x)),
        ),
        _ProSlider(
          title: 'Highlights',
          value: v.highlights,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(highlights: x)),
        ),
        _ProSlider(
          title: 'Shadows',
          value: v.shadows,
          min: -1.0,
          max: 1.0,
          onChanged: (x) => _apply(v.copyWith(shadows: x)),
        ),

        if (_advanced) ...[
          const SizedBox(height: 14),
          _Section('Advanced'),
          _ProSlider(
            title: 'Clarity',
            value: v.clarity,
            min: -1.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(clarity: x)),
          ),
          _ProSlider(
            title: 'Dehaze',
            value: v.dehaze,
            min: -1.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(dehaze: x)),
          ),
          _ProSlider(
            title: 'Gamma',
            value: v.gamma,
            min: 0.5,
            max: 1.5,
            onChanged: (x) => _apply(v.copyWith(gamma: x)),
          ),
          _ProSlider(
            title: 'Fade',
            value: v.fade,
            min: 0.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(fade: x)),
          ),
          _ProSlider(
            title: 'Vignette',
            value: v.vignette,
            min: 0.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(vignette: x)),
          ),
          _ProSlider(
            title: 'Vignette Size',
            value: v.vignetteSize,
            min: 0.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(vignetteSize: x)),
          ),
          _ProSlider(
            title: 'Sharpen',
            value: v.sharpen,
            min: 0.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(sharpen: x)),
          ),
          _ProSlider(
            title: 'Grain',
            value: v.grain,
            min: 0.0,
            max: 1.0,
            onChanged: (x) => _apply(v.copyWith(grain: x)),
          ),
          _ProSwitch(
            title: 'Portrait Blur (hook)',
            value: v.portraitBlur,
            onChanged: (b) => _apply(v.copyWith(portraitBlur: b)),
          ),
        ],
      ],
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final bool advanced;
  final VoidCallback onToggleAdvanced;
  final VoidCallback onReset;

  final VoidCallback? onCompareHoldStart;
  final VoidCallback? onCompareHoldEnd;

  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final bool canUndo;
  final bool canRedo;

  const _HeaderRow({
    required this.advanced,
    required this.onToggleAdvanced,
    required this.onReset,
    this.onCompareHoldStart,
    this.onCompareHoldEnd,
    this.onUndo,
    this.onRedo,
    required this.canUndo,
    required this.canRedo,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Adjust', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const Spacer(),
        _PillButton(label: advanced ? 'ADV: ON' : 'ADV: OFF', onTap: onToggleAdvanced),
        const SizedBox(width: 8),
        _PillButton(label: 'Undo', onTap: canUndo ? onUndo : null),
        const SizedBox(width: 8),
        _PillButton(label: 'Redo', onTap: canRedo ? onRedo : null),
        const SizedBox(width: 8),
        GestureDetector(
          onLongPressStart: (_) => onCompareHoldStart?.call(),
          onLongPressEnd: (_) => onCompareHoldEnd?.call(),
          child: const _PillButton(label: 'Hold Compare', onTap: null),
        ),
        const SizedBox(width: 8),
        _PillButton(label: 'Reset', onTap: onReset),
      ],
    );
  }
}

class _PresetStrip extends StatelessWidget {
  final List<AdjustPreset> presets;
  final ValueChanged<AdjustPreset> onTapPreset;
  const _PresetStrip({required this.presets, required this.onTapPreset});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: presets.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final p = presets[i];
          return InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => onTapPreset(p),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.white24),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Center(child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700))),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          color: Colors.white.withValues(alpha: 0.65),
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ProSlider extends StatelessWidget {
  final String title;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _ProSlider({
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = value.toStringAsFixed(2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
            ],
          ),
          Slider(value: value.clamp(min, max), min: min, max: max, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ProSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ProSwitch({required this.title, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w800))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PillButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: disabled ? 0.45 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
        ),
      ),
    );
  }
}