import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'context_panels.dart';
import 'pro_refine_panel.dart';
import 'reference_image_state.dart';
import 'unified_editor_workspace.dart';

enum ContextPanelPresentation { mobileSheet, sideInspector }

class ActiveContextPanelHost extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedContextPanel activePanel;
  final UnifiedEditorStatus status;

  final ContextPanelPresentation presentation;
  final VoidCallback onClosePanel;

  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;

  final bool showAdvancedInspector;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;

  const ActiveContextPanelHost({
    super.key,
    required this.mode,
    required this.activePanel,
    required this.status,
    required this.presentation,
    required this.onClosePanel,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.showAdvancedInspector,
    this.referenceState = ReferenceImageState.none,
    required this.onAddReference,
  });

  @override
  Widget build(BuildContext context) {
    if (activePanel == UnifiedContextPanel.none) {
      return const SizedBox.shrink();
    }

    final panelTitle = _titleFor(activePanel);

    final panelBody = _panelFor(activePanel, context);

    if (presentation == ContextPanelPresentation.mobileSheet) {
      // Bottom-sheet-like: hero stays visible; panel slides in and stays scrollable.
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: Container(
          key: ValueKey(activePanel),
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTokens.surface.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: AppTokens.border.withValues(alpha: 0.65))),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              _GrabHandle(onClosePanel: onClosePanel),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        panelTitle,
                        style: const TextStyle(
                          color: AppTokens.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      onPressed: onClosePanel,
                      icon: const Icon(Icons.close_rounded, size: 20, color: AppTokens.text2),
                      constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTokens.border, thickness: 0.8),
              Expanded(child: panelBody),
            ],
          ),
        ),
      );
    }

    // Tablet / wide inspector style: fixed-height scroll container.
    final width = (MediaQuery.of(context).size.width * 0.42).clamp(300.0, 420.0);
    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.62),
          border: Border(
            left: BorderSide(color: AppTokens.border.withValues(alpha: 0.6)),
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      panelTitle,
                      style: const TextStyle(
                        color: AppTokens.text,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: onClosePanel,
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTokens.text2),
                    constraints: const BoxConstraints.tightFor(width: 38, height: 38),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppTokens.border, thickness: 0.8),
            Expanded(child: panelBody),
          ],
        ),
      ),
    );
  }

  Widget _panelFor(UnifiedContextPanel panel, BuildContext context) {
    switch (panel) {
      case UnifiedContextPanel.localColorTransfer:
        return LocalColorTransferPanel(
          status: status,
          mode: mode,
          referenceState: referenceState,
        );
      case UnifiedContextPanel.regionControl:
        return RegionControlPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.smartMask:
        return SmartMaskPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.toneLock:
        return ToneLockPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.styleBlend:
        // Route to StyleStealPro when the active style name indicates it
        if (status.activeStyle == 'Style Steal PRO') {
          return StyleStealProPanel(
            status: status,
            mode: mode,
            referenceState: referenceState,
            onAddReference: onAddReference,
          );
        }
        return StyleBlendPanel(
          status: status,
          mode: mode,
          referenceState: referenceState,
        );
      case UnifiedContextPanel.multiSample:
        return MultiSamplePanel(
          status: status,
          mode: mode,
          referenceState: referenceState,
        );
      case UnifiedContextPanel.proRefine:
        return ProRefinePanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.architectMaterials:
        return ArchitectMaterialsPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.sky:
        return SkyPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.lighting:
        return LightingPanel(
          status: status,
          mode: mode,
        );
      case UnifiedContextPanel.export:
        return ExportPanel(
          status: status,
          mode: mode,
          onRequestExport: onRequestExport,
          onRequestSave: onRequestSave,
          onRequestShare: onRequestShare,
        );
      case UnifiedContextPanel.none:
        return const SizedBox.shrink();
    }
  }

  String _titleFor(UnifiedContextPanel panel) {
    switch (panel) {
      case UnifiedContextPanel.localColorTransfer:
        return 'Local Color Transfer';
      case UnifiedContextPanel.regionControl:
        return 'Region Control';
      case UnifiedContextPanel.smartMask:
        return 'Smart Mask';
      case UnifiedContextPanel.toneLock:
        return 'Tone Lock';
      case UnifiedContextPanel.styleBlend:
        return 'Style Blend';
      case UnifiedContextPanel.multiSample:
        return 'Multi-sample Builder';
      case UnifiedContextPanel.proRefine:
        return 'Refine · HSL · Curves';
      case UnifiedContextPanel.architectMaterials:
        return 'Architect Materials';
      case UnifiedContextPanel.sky:
        return 'Sky Matching';
      case UnifiedContextPanel.lighting:
        return 'Lighting';
      case UnifiedContextPanel.export:
        return 'Export';
      case UnifiedContextPanel.none:
        return '';
    }
  }
}

class _GrabHandle extends StatelessWidget {
  final VoidCallback onClosePanel;

  const _GrabHandle({required this.onClosePanel});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onClosePanel,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        child: Container(
          height: 4,
          width: 54,
          decoration: BoxDecoration(
            color: AppTokens.text2.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

