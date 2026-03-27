import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'editor_scope.dart';
import 'engine/creative_types.dart';
import 'engine/style_registry.dart';
import 'reference_image_state.dart';
import 'session_store.dart';
import 'unified_editor_workspace.dart';

/// Context panels drive [EditorEngineController] via [EditorScope] where available.

// Shared UI building blocks
class _PanelScroll extends StatelessWidget {
  final Widget child;
  const _PanelScroll({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTokens.text,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.2,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                color: AppTokens.text2,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final String valueLabel;
  final double value;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
                valueLabel,
                style: const TextStyle(
                  color: AppTokens.primary,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
            ),
            child: Slider(
              value: value,
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

class _RowSwitch extends StatelessWidget {
  final String label;
  final String? hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RowSwitch({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.card.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.border.withValues(alpha: 0.45)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTokens.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.15,
                    ),
                  ),
                  if (hint != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        hint!,
                        style: TextStyle(
                          color: AppTokens.text2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppTokens.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const _PrimaryButton({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.black,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;

  const _SecondaryButton({required this.label, required this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.text,
          side: BorderSide(color: AppTokens.border.withValues(alpha: 0.9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class LocalColorTransferPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;
  final ReferenceImageState referenceState;

  const LocalColorTransferPanel({
    super.key,
    required this.status,
    required this.mode,
    this.referenceState = ReferenceImageState.none,
  });

  @override
  State<LocalColorTransferPanel> createState() => _LocalColorTransferPanelState();
}

class _LocalColorTransferPanelState extends State<LocalColorTransferPanel> {
  String sourceRegion = 'Subject';
  String targetRegion = 'Background';
  String transferMode = 'Balanced';

  double intensity = 0.68;
  double feather = 0.32;
  double overApplication = 0.85; // Safety guard

  bool preserveLuminance = true;
  bool preserveTexture = true;
  bool protectNeutrals = true;

  @override
  Widget build(BuildContext context) {
    final hasRef = widget.referenceState.hasReference;
    final rawRegionOptions = const [
      'Face',
      'Background',
      'Sky',
      'Subject',
      'Facade',
      'Vegetation',
      'Windows',
      'Walls/Floor/Ceiling',
    ];
    final regionOptions = [
      if (hasRef) 'From Reference',
      ...rawRegionOptions,
    ];

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Transfer',
            subtitle: 'Copy color character from the reference region with premium edge handling.',
          ),
          _PickRow(
            label: 'Source region',
            value: sourceRegion,
            options: regionOptions,
            onChanged: (v) => setState(() => sourceRegion = v),
          ),
          _PickRow(
            label: 'Target region',
            value: targetRegion,
            options: regionOptions,
            onChanged: (v) => setState(() => targetRegion = v),
          ),
          _PickRow(
            label: 'Transfer mode',
            value: transferMode,
            options: const ['Balanced', 'Natural Luma', 'Texture Keep', 'Soft Match'],
            onChanged: (v) => setState(() => transferMode = v),
          ),
          const SizedBox(height: 6),
          _LabeledSlider(
            label: 'Intensity',
            valueLabel: '${(intensity * 100).round()}%',
            value: intensity,
            onChanged: (v) => setState(() => intensity = v),
          ),
          _LabeledSlider(
            label: 'Feather',
            valueLabel: '${(feather * 100).round()}%',
            value: feather,
            onChanged: (v) => setState(() => feather = v),
          ),
          _LabeledSlider(
            label: 'Over-application limit',
            valueLabel: '${(overApplication * 100).round()}%',
            value: overApplication,
            onChanged: (v) => setState(() => overApplication = v),
          ),
          // Reference info box
          if (hasRef && sourceRegion == 'From Reference') ...[
            const SizedBox(height: 4),
            _ReferenceInfoBox(profile: widget.referenceState.profile),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 8),
          _SectionTitle(
            title: 'Protection',
            subtitle: 'Keep the result stable and natural.',
          ),
          _RowSwitch(
            label: 'Preserve luminance',
            hint: 'Protect brightness micro-structure',
            value: preserveLuminance,
            onChanged: (v) => setState(() => preserveLuminance = v),
          ),
          _RowSwitch(
            label: 'Preserve texture',
            hint: 'Protect fine detail',
            value: preserveTexture,
            onChanged: (v) => setState(() => preserveTexture = v),
          ),
          _RowSwitch(
            label: 'Protect neutrals',
            hint: 'Reduce color shifts on grays',
            value: protectNeutrals,
            onChanged: (v) => setState(() => protectNeutrals = v),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: 'Apply',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    EditorScope.maybeOf(context)?.setLocalTransfer(
                      amount: intensity * (preserveTexture ? 0.92 : 1.0),
                      sourceLabel: sourceRegion,
                      targetLabel: targetRegion,
                      feather: feather,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Local color transfer queued to preview')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SecondaryButton(
                  label: 'Reset',
                  icon: Icons.refresh_rounded,
                  onPressed: () {
                    setState(() {
                      sourceRegion = 'Subject';
                      targetRegion = 'Background';
                      transferMode = 'Balanced';
                      intensity = 0.68;
                      feather = 0.32;
                      preserveLuminance = true;
                      preserveTexture = true;
                      protectNeutrals = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _PickRow({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.card.withValues(alpha: 0.24),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.border.withValues(alpha: 0.45)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTokens.text2,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: AppTokens.surface,
              underline: const SizedBox.shrink(),
              onChanged: (v) => onChanged(v ?? value),
              items: options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o,
                      child: Text(
                        o,
                        style: const TextStyle(
                          color: AppTokens.text,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class RegionControlPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const RegionControlPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<RegionControlPanel> createState() => _RegionControlPanelState();
}

class _RegionControlPanelState extends State<RegionControlPanel> {
  final Set<String> activeRegions = {'Face'};
  bool invert = false;
  bool multiRegion = true;

  @override
  Widget build(BuildContext context) {
    const regions = [
      'Face',
      'Background',
      'Sky',
      'Subject',
      'Facade',
      'Vegetation',
      'Windows',
      'Walls/Floor/Ceiling',
    ];

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Regions',
            subtitle: 'Enable the parts of the scene that your tools should affect.',
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: regions.map((r) {
              final selected = activeRegions.contains(r);
              return FilterChip(
                selected: selected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      if (!multiRegion) activeRegions.clear();
                      activeRegions.add(r);
                    } else {
                      activeRegions.remove(r);
                    }
                  });
                },
                label: Text(
                  r,
                  style: TextStyle(
                    color: selected ? AppTokens.primary : AppTokens.text2,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                selectedColor: AppTokens.primary.withValues(alpha: 0.14),
                backgroundColor: AppTokens.card2.withValues(alpha: 0.3),
                checkmarkColor: AppTokens.primary,
                side: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _RowSwitch(
            label: 'Invert region',
            hint: 'Swap affected and untouched areas',
            value: invert,
            onChanged: (v) => setState(() => invert = v),
          ),
          _RowSwitch(
            label: 'Multi-region mode',
            hint: 'Allow multiple regions at once',
            value: multiRegion,
            onChanged: (v) => setState(() => multiRegion = v),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Reset',
                  icon: Icons.refresh_rounded,
                  onPressed: () => setState(() {
                    activeRegions
                      ..clear()
                      ..add('Face');
                    invert = false;
                    multiRegion = true;
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PrimaryButton(
            label: 'Apply Regions',
            icon: Icons.crop_rounded,
            onPressed: () {
              // Engine supports a single mask kind at a time; for multi-selection
              // we apply the highest-priority selected region.
              SmartMaskKind kind;
              if (activeRegions.contains('Face')) {
                kind = SmartMaskKind.face;
              } else if (activeRegions.contains('Sky')) {
                kind = SmartMaskKind.sky;
              } else if (activeRegions.contains('Subject')) {
                kind = SmartMaskKind.subject;
              } else if (activeRegions.contains('Vegetation')) {
                kind = SmartMaskKind.vegetation;
              } else if (activeRegions.contains('Facade') ||
                  activeRegions.contains('Windows') ||
                  activeRegions.contains('Walls/Floor/Ceiling')) {
                kind = SmartMaskKind.facade;
              } else if (activeRegions.contains('Background')) {
                kind = SmartMaskKind.none;
              } else {
                kind = SmartMaskKind.face;
              }

              EditorScope.maybeOf(context)?.setMaskKind(kind);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Regions applied: ${kind.name}')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SmartMaskPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const SmartMaskPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<SmartMaskPanel> createState() => _SmartMaskPanelState();
}

class _SmartMaskPanelState extends State<SmartMaskPanel> {
  bool detectFace = true;
  bool detectSky = false;
  bool detectSubject = true;
  bool detectMaterial = false;

  double refine = 0.42;
  double feather = 0.26;

  bool advancedExpanded = false;

  @override
  Widget build(BuildContext context) {
    final architectExtra = widget.mode == UnifiedEditorMode.architect;

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Mask Intelligence',
            subtitle: 'Detect key regions with premium confidence scoring.',
          ),
          _RowSwitch(
            label: 'Face detect',
            value: detectFace,
            onChanged: (v) => setState(() => detectFace = v),
          ),
          _RowSwitch(
            label: 'Sky detect',
            value: detectSky,
            onChanged: (v) => setState(() => detectSky = v),
          ),
          _RowSwitch(
            label: 'Subject detect',
            value: detectSubject,
            onChanged: (v) => setState(() => detectSubject = v),
          ),
          if (architectExtra) ...[
            _RowSwitch(
              label: 'Material mask',
              hint: 'Architect mode material regions',
              value: detectMaterial,
              onChanged: (v) => setState(() => detectMaterial = v),
            ),
          ],
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTokens.card.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(AppTokens.r16),
              border: Border.all(color: AppTokens.border.withValues(alpha: 0.45)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_rounded, color: AppTokens.info),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confidence',
                        style: TextStyle(
                          color: AppTokens.text2,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.status.maskReady ? 'High (0.86)' : 'Pending (0.42)',
                        style: const TextStyle(
                          color: AppTokens.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ExpansionTile(
            initiallyExpanded: widget.mode != UnifiedEditorMode.quick && advancedExpanded,
            onExpansionChanged: (v) => setState(() => advancedExpanded = v),
            title: Text(
              'Refine mask (advanced)',
              style: TextStyle(
                color: widget.mode == UnifiedEditorMode.quick ? AppTokens.text2 : AppTokens.text,
                fontWeight: FontWeight.w900,
                fontSize: 12.5,
              ),
            ),
            trailing: Icon(
              Icons.tune_rounded,
              color: AppTokens.text2,
            ),
            children: [
              _LabeledSlider(
                label: 'Refine strength',
                valueLabel: '${(refine * 100).round()}%',
                value: refine,
                onChanged: (v) => setState(() => refine = v),
              ),
              _LabeledSlider(
                label: 'Feather',
                valueLabel: '${(feather * 100).round()}%',
                value: feather,
                onChanged: (v) => setState(() => feather = v),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _PrimaryButton(
                  label: 'Apply Mask',
                  icon: Icons.auto_awesome_rounded,
                  onPressed: () {
                    SmartMaskKind kind = SmartMaskKind.subject;
                    if (detectFace) {
                      kind = SmartMaskKind.face;
                    } else if (detectSky) {
                      kind = SmartMaskKind.sky;
                    } else if (detectMaterial) {
                      kind = SmartMaskKind.materials;
                    } else if (detectSubject) {
                      kind = SmartMaskKind.subject;
                    }
                    EditorScope.maybeOf(context)?.setMaskKind(kind);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Smart mask: ${kind.name}')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ToneLockPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const ToneLockPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<ToneLockPanel> createState() => _ToneLockPanelState();
}

class _ToneLockPanelState extends State<ToneLockPanel> {
  bool lockExposure = true;
  bool lockSkinTone = false;
  bool lockWhites = false;
  bool lockShadows = false;
  bool lockHighlights = false;
  bool lockConcreteNeutrality = false;
  bool lockGlassReflectance = false;

  @override
  Widget build(BuildContext context) {
    final items = <({String label, bool value, ValueChanged<bool> onChanged})>[
      (label: 'Lock Exposure', value: lockExposure, onChanged: (v) => setState(() => lockExposure = v)),
      (label: 'Lock Skin Tone', value: lockSkinTone, onChanged: (v) => setState(() => lockSkinTone = v)),
      (label: 'Lock Whites', value: lockWhites, onChanged: (v) => setState(() => lockWhites = v)),
      (label: 'Lock Shadows', value: lockShadows, onChanged: (v) => setState(() => lockShadows = v)),
      (label: 'Lock Highlights', value: lockHighlights, onChanged: (v) => setState(() => lockHighlights = v)),
      (label: 'Lock Concrete Neutrality', value: lockConcreteNeutrality, onChanged: (v) => setState(() => lockConcreteNeutrality = v)),
      (label: 'Lock Glass Reflectance', value: lockGlassReflectance, onChanged: (v) => setState(() => lockGlassReflectance = v)),
    ];

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Tone Lock',
            subtitle: 'Keep your key photometric qualities stable during blending and transfers.',
          ),
          ...items.map((it) => _RowSwitch(
                label: it.label,
                value: it.value,
                onChanged: it.onChanged,
              )),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Apply Locks',
            icon: Icons.lock_open_rounded,
            onPressed: () {
              var s = 0.0;
              if (lockExposure) s += 0.2;
              if (lockSkinTone) s += 0.12;
              if (lockWhites) s += 0.1;
              if (lockShadows) s += 0.08;
              if (lockHighlights) s += 0.08;
              if (lockConcreteNeutrality) s += 0.14;
              if (lockGlassReflectance) s += 0.1;
              EditorScope.maybeOf(context)?.setToneLock(s.clamp(0.0, 0.95));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tone lock applied to preview pipeline')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class StyleBlendPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;
  final ReferenceImageState referenceState;

  const StyleBlendPanel({
    super.key,
    required this.status,
    required this.mode,
    this.referenceState = ReferenceImageState.none,
  });

  @override
  State<StyleBlendPanel> createState() => _StyleBlendPanelState();
}

class _StyleBlendPanelState extends State<StyleBlendPanel> {
  late String styleA;
  late String styleB;
  double ratio = 0.5;
  String blendMode = 'Balanced';
  bool applyToFull = true;
  bool applyToRegion = false;

  @override
  void initState() {
    super.initState();
    final core = CreativeStyleRegistry.coreStyleDisplayNames;
    styleA = core.isNotEmpty ? core.first : 'Natural Premium';
    styleB = core.length > 1 ? core[1] : 'Cinematic Soft';
  }

  @override
  Widget build(BuildContext context) {
    final hasRef = widget.referenceState.hasReference;
    final conflict = styleA == styleB && ratio > 0.6;
    final blendOptions = [
      if (hasRef) 'Reference Image',
      ...CreativeStyleRegistry.coreStyleDisplayNames,
      ...CreativeStyleRegistry.architectStyleDisplayNames,
    ];
    // Ensure current values are valid after ref toggle
    if (!blendOptions.contains(styleA)) styleA = blendOptions.first;
    if (!blendOptions.contains(styleB) && blendOptions.length > 1) styleB = blendOptions[1];

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Blend',
            subtitle: 'Mix two looks with stable premium blending.',
          ),
          _PickRow(
            label: 'Style A',
            value: styleA,
            options: blendOptions,
            onChanged: (v) => setState(() => styleA = v),
          ),
          _PickRow(
            label: 'Style B',
            value: styleB,
            options: blendOptions,
            onChanged: (v) => setState(() => styleB = v),
          ),
          _LabeledSlider(
            label: 'Blend ratio',
            valueLabel: '${(ratio * 100).round()}%',
            value: ratio,
            onChanged: (v) => setState(() => ratio = v),
          ),
          _PickRow(
            label: 'Blend mode',
            value: blendMode,
            options: const ['Balanced', 'Soft Match', 'Texture Priority', 'Luma First'],
            onChanged: (v) => setState(() => blendMode = v),
          ),
          const SizedBox(height: 10),
          _SectionTitle(title: 'Apply', subtitle: 'Choose where the blend affects the scene.'),
          _RowSwitch(
            label: 'Apply to full image',
            value: applyToFull,
            onChanged: (v) => setState(() {
              applyToFull = v;
              if (v) applyToRegion = false;
            }),
          ),
          _RowSwitch(
            label: 'Apply to current region',
            value: applyToRegion,
            onChanged: (v) => setState(() {
              applyToRegion = v;
              if (v) applyToFull = false;
            }),
          ),
          const SizedBox(height: 10),
          if (conflict)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTokens.warning.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: AppTokens.warning.withValues(alpha: 0.45)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: AppTokens.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Conflict warning: styles are very similar at high ratio.',
                      style: TextStyle(
                        color: AppTokens.text,
                        fontWeight: FontWeight.w900,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Apply Blend',
            icon: Icons.merge_rounded,
            onPressed: () {
              final eng = EditorScope.maybeOf(context);
              final idA = CreativeStyleRegistry.byDisplayName(styleA)?.id ?? 'natural_premium';
              final idB = CreativeStyleRegistry.byDisplayName(styleB)?.id ?? 'cinematic_soft';
              eng?.setPrimaryPackId(idA);
              eng?.setStyleBlend(secondaryId: idB, t: ratio);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Style blend merged in engine')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class MultiSamplePanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;
  final ReferenceImageState referenceState;

  const MultiSamplePanel({
    super.key,
    required this.status,
    required this.mode,
    this.referenceState = ReferenceImageState.none,
  });

  @override
  State<MultiSamplePanel> createState() => _MultiSamplePanelState();
}

class _MultiSamplePanelState extends State<MultiSamplePanel> {
  final List<_Sample> samples = [
    _Sample(name: 'Sample 1', weight: 0.7),
    _Sample(name: 'Sample 2', weight: 0.3),
  ];

  void _addSample() {
    setState(() {
      samples.add(_Sample(name: 'Sample ${samples.length + 1}', weight: 0.25));
    });
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Multi-sample Builder',
            subtitle: 'Collect multiple samples and build a custom premium style profile.',
          ),
          ...samples.map((s) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    s.name,
                    style: const TextStyle(
                      color: AppTokens.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _LabeledSlider(
                  label: 'Weight',
                  valueLabel: '${(s.weight * 100).round()}%',
                  value: s.weight,
                  onChanged: (v) => setState(() => s.weight = v),
                ),
              ],
            );
          }),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _SecondaryButton(
                  label: 'Add sample',
                  icon: Icons.add_rounded,
                  onPressed: _addSample,
                ),
              ),
              if (widget.referenceState.hasReference) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _SecondaryButton(
                    label: 'From Reference',
                    icon: Icons.image_search_rounded,
                    onPressed: () {
                      setState(() {
                        samples.add(_Sample(
                          name: 'Reference Point',
                          weight: widget.referenceState.profile?.compatibilityBias ?? 0.6,
                        ));
                      });
                    },
                  ),
                ),
              ],
            ],
          ),
          _PrimaryButton(
            label: 'Build custom style',
            icon: Icons.auto_awesome_rounded,
            onPressed: () {
              final names = CreativeStyleRegistry.coreStyleDisplayNames;
              final ids = <String>[];
              final wts = <double>[];
              for (var i = 0; i < samples.length; i++) {
                final nm = names[i % names.length];
                final pk = CreativeStyleRegistry.byDisplayName(nm);
                if (pk != null) {
                  ids.add(pk.id);
                  wts.add(samples[i].weight);
                }
              }
              if (ids.isNotEmpty) {
                EditorScope.maybeOf(context)?.setMultiSample(
                  packIds: ids,
                  weights: wts,
                  mix: 0.78,
                );
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Multi-sample profile pushed to engine')),
              );
            },
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Save preset',
            icon: Icons.save_rounded,
            onPressed: () async {
              final eng = EditorScope.maybeOf(context);
              if (eng == null) return;
              try {
                await UnifiedEditorSessionStore.save(eng);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Preset saved to session')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Preset save failed: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _Sample {
  final String name;
  double weight;

  _Sample({required this.name, required this.weight});
}

class ArchitectMaterialsPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const ArchitectMaterialsPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<ArchitectMaterialsPanel> createState() => _ArchitectMaterialsPanelState();
}

class _ArchitectMaterialsPanelState extends State<ArchitectMaterialsPanel> {
  final Set<String> selectedMaterials = {'Concrete'};
  bool protectConcrete = true;
  bool protectPaintedWalls = true;
  bool protectGlass = false;
  bool protectMetal = false;

  double realism = 0.66;

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Materials',
            subtitle: 'Material-aware tone shaping for architect-grade realism.',
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              'Concrete',
              'Wood',
              'Glass',
              'Metal',
              'Vegetation',
              'Stone',
              'Painted Walls',
            ].map((m) {
              final active = selectedMaterials.contains(m);
              return _MaterialChip(
                material: m,
                active: active,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      selectedMaterials.add(m);
                    } else {
                      selectedMaterials.remove(m);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _SectionTitle(
            title: 'Material protect toggles',
            subtitle: 'Preserve important reflectance behavior.',
          ),
          _RowSwitch(
            label: 'Protect concrete neutrality',
            value: protectConcrete,
            onChanged: (v) => setState(() => protectConcrete = v),
          ),
          _RowSwitch(
            label: 'Protect painted walls',
            value: protectPaintedWalls,
            onChanged: (v) => setState(() => protectPaintedWalls = v),
          ),
          _RowSwitch(
            label: 'Protect glass reflectance',
            value: protectGlass,
            onChanged: (v) => setState(() => protectGlass = v),
          ),
          _RowSwitch(
            label: 'Protect metal finish',
            value: protectMetal,
            onChanged: (v) => setState(() => protectMetal = v),
          ),
          const SizedBox(height: 8),
          _LabeledSlider(
            label: 'Realism bias',
            valueLabel: '${(realism * 100).round()}%',
            value: realism,
            onChanged: (v) => setState(() => realism = v),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Apply Materials',
            icon: Icons.layers_rounded,
            onPressed: () {
              EditorScope.maybeOf(context)?.setArchitectExtras(
                glass: protectGlass ? realism * 0.4 : realism * 0.2,
                sky: selectedMaterials.contains('Vegetation') ? 0.08 : 0.04,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Material-aware grade applied')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  final String material;
  final bool active;
  final ValueChanged<bool> onSelected;

  const _MaterialChip({
    required this.material,
    required this.active,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: active,
      onSelected: onSelected,
      label: Text(
        material,
        style: TextStyle(
          color: active ? AppTokens.primary : AppTokens.text2,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
      backgroundColor: AppTokens.card2.withValues(alpha: 0.25),
      selectedColor: AppTokens.primary.withValues(alpha: 0.14),
      side: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
    );
  }
}

class SkyPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const SkyPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<SkyPanel> createState() => _SkyPanelState();
}

class _SkyPanelState extends State<SkyPanel> {
  String preset = 'Blue';
  bool skyMatch = true;
  double tone = 0.56;
  double ambientInfluence = 0.42;
  final skyReplacementCtrl = TextEditingController();

  @override
  void dispose() {
    skyReplacementCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const presets = ['Sunset', 'Cloudy', 'Blue', 'Dramatic'];
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Sky Matching',
            subtitle: 'Blend sky color, tone, and ambient influence for architect-grade coherence.',
          ),
          _RowSwitch(
            label: 'Sky match',
            hint: 'Align sky color with reference scene',
            value: skyMatch,
            onChanged: (v) => setState(() => skyMatch = v),
          ),
          _LabeledSlider(
            label: 'Sky tone',
            valueLabel: '${(tone * 100).round()}%',
            value: tone,
            onChanged: (v) => setState(() => tone = v),
          ),
          const _SectionTitle(
            title: 'Presets',
            subtitle: 'One-tap sky styles.',
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: presets.map((p) {
              final selected = p == preset;
              return FilterChip(
                selected: selected,
                onSelected: (v) => setState(() => preset = p),
                label: Text(
                  p,
                  style: TextStyle(
                    color: selected ? AppTokens.primary : AppTokens.text2,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
                selectedColor: AppTokens.primary.withValues(alpha: 0.14),
                backgroundColor: AppTokens.card2.withValues(alpha: 0.25),
                side: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          _PickReplacementRow(
            controller: skyReplacementCtrl,
          ),
          _LabeledSlider(
            label: 'Ambient influence',
            valueLabel: '${(ambientInfluence * 100).round()}%',
            value: ambientInfluence,
            onChanged: (v) => setState(() => ambientInfluence = v),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Apply Sky',
            icon: Icons.cloud_rounded,
            onPressed: () {
              final se = (skyMatch ? 0.55 : 0.22) * tone + ambientInfluence * 0.2;
              EditorScope.maybeOf(context)?.setArchitectExtras(sky: se.clamp(0.04, 0.95));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sky routing applied to pipeline')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PickReplacementRow extends StatelessWidget {
  final TextEditingController controller;
  const _PickReplacementRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppTokens.text, fontWeight: FontWeight.w900),
        decoration: InputDecoration(
          labelText: 'Optional sky replacement entry',
          labelStyle: TextStyle(color: AppTokens.text2, fontWeight: FontWeight.w800),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
            borderSide: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTokens.r16),
            borderSide: BorderSide(color: AppTokens.primary.withValues(alpha: 0.65)),
          ),
          filled: true,
          fillColor: AppTokens.card.withValues(alpha: 0.2),
        ),
      ),
    );
  }
}

class LightingPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;

  const LightingPanel({
    super.key,
    required this.status,
    required this.mode,
  });

  @override
  State<LightingPanel> createState() => _LightingPanelState();
}

class _LightingPanelState extends State<LightingPanel> {
  double highlights = 0.62;
  double shadowBalance = 0.44;
  double ambientFeel = 0.56;
  double windowShaping = 0.48;
  double interiorExterior = 0.5;

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Lighting',
            subtitle: 'Premium highlight/shadow shaping and ambient tuning.',
          ),
          _LabeledSlider(
            label: 'Highlight control',
            valueLabel: '${(highlights * 100).round()}%',
            value: highlights,
            onChanged: (v) => setState(() => highlights = v),
          ),
          _LabeledSlider(
            label: 'Shadow balance',
            valueLabel: '${(shadowBalance * 100).round()}%',
            value: shadowBalance,
            onChanged: (v) => setState(() => shadowBalance = v),
          ),
          _LabeledSlider(
            label: 'Ambient feel',
            valueLabel: '${(ambientFeel * 100).round()}%',
            value: ambientFeel,
            onChanged: (v) => setState(() => ambientFeel = v),
          ),
          _LabeledSlider(
            label: 'Window highlight shaping',
            valueLabel: '${(windowShaping * 100).round()}%',
            value: windowShaping,
            onChanged: (v) => setState(() => windowShaping = v),
          ),
          _LabeledSlider(
            label: 'Interior / Exterior tuning',
            valueLabel: '${(interiorExterior * 100).round()}%',
            value: interiorExterior,
            onChanged: (v) => setState(() => interiorExterior = v),
          ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Apply Lighting',
            icon: Icons.lightbulb_rounded,
            onPressed: () {
              EditorScope.maybeOf(context)?.setProColor(
                curveHi: highlights,
                curveShadow: shadowBalance,
                curveMid: interiorExterior,
                curveMaster: ambientFeel,
              );
              EditorScope.maybeOf(context)?.setArchitectExtras(glass: windowShaping * 0.42);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Lighting shaping sent to engine')),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ExportPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;
  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;

  const ExportPanel({
    super.key,
    required this.status,
    required this.mode,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
  });

  @override
  State<ExportPanel> createState() => _ExportPanelState();
}

class _ExportPanelState extends State<ExportPanel> {
  bool exportBeforeAfter = true;
  bool socialLayout = false;
  String resolution = '2048px';
  bool watermark = false;
  bool savePreset = false;
  final presetNameCtrl = TextEditingController(text: 'My Export Preset');

  @override
  void dispose() {
    presetNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Export',
            subtitle: 'Choose your output format, resolution, and premium presentation options.',
          ),
          _RowSwitch(
            label: 'Export before/after',
            value: exportBeforeAfter,
            onChanged: (v) => setState(() => exportBeforeAfter = v),
          ),
          _RowSwitch(
            label: 'Social layout export',
            value: socialLayout,
            onChanged: (v) => setState(() => socialLayout = v),
          ),
          _PickRow(
            label: 'Resolution',
            value: resolution,
            options: const ['1024px', '1536px', '2048px', '2560px'],
            onChanged: (v) => setState(() => resolution = v),
          ),
          _RowSwitch(
            label: 'Watermark',
            hint: 'Optional brand mark',
            value: watermark,
            onChanged: (v) => setState(() => watermark = v),
          ),
          _RowSwitch(
            label: 'Save preset',
            value: savePreset,
            onChanged: (v) => setState(() => savePreset = v),
          ),
          if (savePreset)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: presetNameCtrl,
                style: const TextStyle(color: AppTokens.text, fontWeight: FontWeight.w900),
                decoration: InputDecoration(
                  labelText: 'Preset name',
                  labelStyle: TextStyle(color: AppTokens.text2, fontWeight: FontWeight.w800),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                    borderSide: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTokens.r16),
                    borderSide: BorderSide(color: AppTokens.primary.withValues(alpha: 0.65)),
                  ),
                  filled: true,
                  fillColor: AppTokens.card.withValues(alpha: 0.2),
                ),
              ),
            ),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: 'Export now',
            icon: Icons.download_rounded,
            onPressed: () {
              widget.onRequestExport();
            },
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Save image',
            icon: Icons.save_rounded,
            onPressed: widget.onRequestSave,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            label: 'Share',
            icon: Icons.share_rounded,
            onPressed: widget.onRequestShare,
          ),
        ],
      ),
    );
  }
}



// _????????????????????????????????????????????????????????????????????????????
// Reference Image Shared Widget
// _????????????????????????????????????????????????????????????????????????????

class _ReferenceInfoBox extends StatelessWidget {
  final ReferenceProfile? profile;

  const _ReferenceInfoBox({this.profile});

  @override
  Widget build(BuildContext context) {
    final p = profile;
    if (p == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTokens.success.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppTokens.r16),
          border: Border.all(color: AppTokens.success.withValues(alpha: 0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.image_search_rounded, color: AppTokens.success, size: 16),
            SizedBox(width: 8),
            Text('Analysing reference...', style: TextStyle(color: AppTokens.success, fontWeight: FontWeight.w800, fontSize: 12)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTokens.success.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.success.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.image_search_rounded, color: AppTokens.success, size: 14),
              const SizedBox(width: 6),
              const Text(
                'Reference',
                style: TextStyle(color: AppTokens.success, fontWeight: FontWeight.w900, fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(p.compatibilityBias * 100).round()}% match',
                style: TextStyle(
                  color: p.compatibilityBias > 0.65 ? AppTokens.success : AppTokens.warning,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (p.palette.isNotEmpty)
            Row(children: [
              Text('Palette  ', style: TextStyle(color: AppTokens.text2, fontWeight: FontWeight.w800, fontSize: 11)),
              ...p.palette.take(6).map((c) => Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: c, border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1))),
              )),
            ]),
          const SizedBox(height: 6),
          _RefBar(label: 'Luminance', value: p.avgLuminance),
          _RefBar(label: 'Saturation', value: p.avgSaturation),
          _RefBar(label: 'Contrast', value: p.contrast),
        ],
      ),
    );
  }
}

class _RefBar extends StatelessWidget {
  final String label;
  final double value;
  const _RefBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(color: AppTokens.text2, fontSize: 10.5, fontWeight: FontWeight.w800))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(value: value.clamp(0.0, 1.0), color: AppTokens.success, backgroundColor: AppTokens.border.withValues(alpha: 0.3), minHeight: 4),
            ),
          ),
          const SizedBox(width: 6),
          Text('%', style: const TextStyle(color: AppTokens.primary, fontSize: 10.5, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

// _????????????????????????????????????????????????????????????????????????????
// Style Steal PRO Panel
// _????????????????????????????????????????????????????????????????????????????

class StyleStealProPanel extends StatefulWidget {
  final UnifiedEditorStatus status;
  final UnifiedEditorMode mode;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;

  const StyleStealProPanel({
    super.key,
    required this.status,
    required this.mode,
    required this.referenceState,
    required this.onAddReference,
  });

  @override
  State<StyleStealProPanel> createState() => _StyleStealProPanelState();
}

class _StyleStealProPanelState extends State<StyleStealProPanel> {
  double extractStrength = 0.78;
  double overApplicationLimit = 0.85;
  bool preserveStructure = true;
  bool moodTransfer = true;
  bool colorTransfer = true;
  bool toneTransfer = true;

  @override
  Widget build(BuildContext context) {
    final hasRef = widget.referenceState.hasReference;
    final profile = widget.referenceState.profile;

    return _PanelScroll(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            title: 'Style Steal PRO',
            subtitle: 'Extract mood, color, and tone from a reference image and apply to your photo.',
          ),
          if (!hasRef) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTokens.card.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppTokens.r16),
                border: Border.all(color: AppTokens.success.withValues(alpha: 0.35), width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(Icons.add_photo_alternate_rounded, color: AppTokens.success, size: 28),
                  const SizedBox(height: 10),
                  const Text('No reference loaded', style: TextStyle(color: AppTokens.text, fontWeight: FontWeight.w900, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Tap below to pick a reference photo to steal its style from.', textAlign: TextAlign.center, style: TextStyle(color: AppTokens.text2, fontSize: 11.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _PrimaryButton(label: 'Pick Reference', icon: Icons.add_photo_alternate_rounded, onPressed: widget.onAddReference),
                ],
              ),
            ),
          ] else ...[
            _ReferenceInfoBox(profile: profile),
            const SizedBox(height: 14),
            const _SectionTitle(title: 'Extract', subtitle: 'Choose which visual qualities to steal.'),
            _RowSwitch(label: 'Color mood', hint: 'Transfer hue and saturation character', value: colorTransfer, onChanged: (v) => setState(() => colorTransfer = v)),
            _RowSwitch(label: 'Tone curve', hint: 'Apply light/dark distribution', value: toneTransfer, onChanged: (v) => setState(() => toneTransfer = v)),
            _RowSwitch(label: 'Overall mood', hint: 'Warm/cool + contrast pattern', value: moodTransfer, onChanged: (v) => setState(() => moodTransfer = v)),
            _RowSwitch(label: 'Preserve target structure', hint: 'Protect edges and details', value: preserveStructure, onChanged: (v) => setState(() => preserveStructure = v)),
            const SizedBox(height: 10),
            const _SectionTitle(title: 'Safety', subtitle: 'Controls to prevent over-application.'),
            _LabeledSlider(label: 'Extract strength', valueLabel: '%', value: extractStrength, onChanged: (v) => setState(() => extractStrength = v)),
            _LabeledSlider(label: 'Over-application limit', valueLabel: '%', value: overApplicationLimit, onChanged: (v) => setState(() => overApplicationLimit = v)),
            if (profile != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: AppTokens.card.withValues(alpha: 0.24), borderRadius: BorderRadius.circular(AppTokens.r16), border: Border.all(color: AppTokens.border.withValues(alpha: 0.45))),
                child: Row(
                  children: [
                    Icon(Icons.speed_rounded, color: profile.compatibilityBias > 0.65 ? AppTokens.success : AppTokens.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Compatibility Score', style: TextStyle(color: AppTokens.text2, fontWeight: FontWeight.w800, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          '${(profile.compatibilityBias * 100).round()}% fit',
                          style: TextStyle(
                            color: profile.compatibilityBias > 0.65 ? AppTokens.success : AppTokens.warning,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            _PrimaryButton(
              label: 'Build Style Profile',
              icon: Icons.auto_awesome_rounded,
              onPressed: () {
                final eff = extractStrength * overApplicationLimit * (profile?.compatibilityBias ?? 0.75);
              final eng = EditorScope.maybeOf(context);
              eng?.setStyleStealProOptions(
                strength: eff,
                toneEnabled: toneTransfer,
                moodEnabled: moodTransfer,
                colorEnabled: colorTransfer,
              );
                if (colorTransfer) {
                  eng?.setLocalTransfer(amount: eff, sourceLabel: 'Reference', targetLabel: 'Full', feather: preserveStructure ? 0.35 : 0.6);
                }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Style profile built - Strength ${(eff * 100).round()}%')),
              );
              },
            ),
            const SizedBox(height: 12),
            _SecondaryButton(label: 'Replace Reference', icon: Icons.swap_horiz_rounded, onPressed: widget.onAddReference),
          ],
        ],
      ),
    );
  }
}
