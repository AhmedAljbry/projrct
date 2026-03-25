import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'unified_editor_workspace.dart';

class AdvancedInspector extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;
  final bool expanded;
  final VoidCallback onToggle;

  const AdvancedInspector({
    super.key,
    required this.mode,
    required this.status,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final label = 'Advanced Inspector';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppTokens.surface.withValues(alpha: 0.55),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.55)),
        borderRadius: BorderRadius.circular(AppTokens.r16),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(AppTokens.r16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 20,
                    color: AppTokens.text2,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: AppTokens.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTokens.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppTokens.primary.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      '${(status.compatibilityScore * 100).toStringAsFixed(0)}% fit',
                      style: TextStyle(
                        color: AppTokens.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: _expandedBody(),
            crossFadeState: expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }

  Widget _expandedBody() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Section(
            title: 'Compatibility',
            subtitle: 'How well the current look matches the scene.',
            rows: [
              _Row(label: 'Scene match', value: '${(status.compatibilityScore * 100).toStringAsFixed(0)}%'),
              _Row(label: 'Style DNA stability', value: status.styleDnaDigest.isEmpty ? '—' : status.styleDnaDigest),
              _Row(label: 'Scene router', value: status.sceneKindLabel.isEmpty ? '—' : status.sceneKindLabel),
            ],
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Diagnostics',
            subtitle: 'Processing signals & safety checks.',
            rows: [
              _Row(label: 'Mask confidence', value: status.maskReady ? '0.86' : '0.42'),
              _Row(label: 'Material confidence', value: status.materialDetected ? '0.81' : '0.36'),
              _Row(label: 'Neutrality protection', value: status.toneLockActive ? 'ON' : 'OFF'),
            ],
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Style DNA',
            subtitle: 'Premium signature summary for power users.',
            rows: [
              _Row(label: 'Tone profile', value: status.activeStyle),
              _Row(label: 'Pack trace', value: status.styleDnaDigest.isEmpty ? 'core' : status.styleDnaDigest),
              _Row(label: 'Architect bias', value: mode == UnifiedEditorMode.architect ? 'Active' : 'Neutral'),
            ],
          ),
          const SizedBox(height: 10),
          _Section(
            title: 'Processing State',
            subtitle: 'Live rendering path: load → scene → masks → grade → safety → preview/export.',
            rows: [
              _Row(label: 'Engine queue', value: status.architectAssistActive ? 'Primed' : 'Idle'),
              _Row(label: 'Render mode', value: mode.toString().split('.').last),
              _Row(label: 'Output readiness', value: status.compareActive ? 'Preview + export' : 'Preview'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Row> rows;

  const _Section({
    required this.title,
    required this.subtitle,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTokens.card.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppTokens.r16),
        border: Border.all(color: AppTokens.border.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTokens.text,
              fontWeight: FontWeight.w900,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: AppTokens.text2,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _KpiRow(label: r.label, value: r.value),
              )),
        ],
      ),
    );
  }
}

class _Row {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});
}

class _KpiRow extends StatelessWidget {
  final String label;
  final String value;

  const _KpiRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppTokens.text2,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTokens.primary,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

