import 'package:flutter/material.dart';
import 'package:untitled2/core/utils/Responsive.dart';

import 'advanced_inspector.dart';
import 'active_context_panel_host.dart';
import 'hero_canvas_section.dart';
import 'quick_style_rail.dart';
import 'reference_image_state.dart';
import 'unified_editor_workspace.dart';
import 'workspace_adaptive_dock.dart';

class MobileWorkspaceLayout extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedDockAction activeDock;
  final UnifiedContextPanel activePanel;

  final bool showAdvancedInspector;
  final UnifiedEditorStatus status;

  final bool compareEnabled;
  final double compareSplit;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  final ValueChanged<UnifiedDockAction> onDockTapped;
  final ValueChanged<double> onCompareSplitChanged;
  final ValueChanged<UnifiedContextPanel> onActivePanelChanged;
  final ValueChanged<String> onStyleSelected;
  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;
  final VoidCallback onAdvancedInspectorToggle;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;

  const MobileWorkspaceLayout({
    super.key,
    required this.mode,
    required this.activeDock,
    required this.activePanel,
    required this.showAdvancedInspector,
    required this.status,
    required this.compareEnabled,
    required this.compareSplit,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
    required this.onDockTapped,
    required this.onCompareSplitChanged,
    required this.onActivePanelChanged,
    required this.onStyleSelected,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.onAdvancedInspectorToggle,
    this.referenceState = ReferenceImageState.none,
    required this.onAddReference,
  });

  @override
  Widget build(BuildContext context) {
    const dockHeight = 118.0;
    final panelMaxHeight = Responsive.bottomPanelHeight(context) - 12;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12),
          child: Column(
            children: [
              Expanded(
                child: HeroCanvasSection(
                  mode: mode,
                  status: status,
                  compareEnabled: compareEnabled,
                  compareSplit: compareSplit,
                  onCompareSplitChanged: onCompareSplitChanged,
                  beforeImage: beforeImage,
                  afterImage: afterImage,
                  emptyCanvas: emptyCanvas,
                ),
              ),
              const SizedBox(height: 10),
              QuickStyleRail(
                mode: mode,
                status: status,
                onStyleSelected: onStyleSelected,
              ),
              SizedBox(height: dockHeight),
            ],
          ),
        ),

        // Contextual bottom sheet.
        Positioned(
          left: 0,
          right: 0,
          bottom: dockHeight,
          child: activePanel == UnifiedContextPanel.none
              ? const SizedBox.shrink()
              : SizedBox(
                  height: panelMaxHeight.clamp(260.0, 420.0),
                  child: ActiveContextPanelHost(
                    mode: mode,
                    activePanel: activePanel,
                    status: status,
                    presentation: ContextPanelPresentation.mobileSheet,
                    onClosePanel: () => onActivePanelChanged(UnifiedContextPanel.none),
                    onRequestExport: onRequestExport,
                    onRequestSave: onRequestSave,
                    onRequestShare: onRequestShare,
                    showAdvancedInspector: showAdvancedInspector,
                    referenceState: referenceState,
                    onAddReference: onAddReference,
                  ),
                ),
        ),

        // Dock stays anchored.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: WorkspaceAdaptiveDock(
            mode: mode,
            activeDock: activeDock,
            height: dockHeight,
            onDockTapped: onDockTapped,
          ),
        ),
      ],
    );
  }
}

class TabletWorkspaceLayout extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedDockAction activeDock;
  final UnifiedContextPanel activePanel;

  final bool showAdvancedInspector;
  final UnifiedEditorStatus status;

  final bool compareEnabled;
  final double compareSplit;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  final ValueChanged<UnifiedDockAction> onDockTapped;
  final ValueChanged<double> onCompareSplitChanged;
  final ValueChanged<UnifiedContextPanel> onActivePanelChanged;
  final ValueChanged<String> onStyleSelected;
  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;
  final VoidCallback onAdvancedInspectorToggle;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;

  const TabletWorkspaceLayout({
    super.key,
    required this.mode,
    required this.activeDock,
    required this.activePanel,
    required this.showAdvancedInspector,
    required this.status,
    required this.compareEnabled,
    required this.compareSplit,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
    required this.onDockTapped,
    required this.onCompareSplitChanged,
    required this.onActivePanelChanged,
    required this.onStyleSelected,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.onAdvancedInspectorToggle,
    this.referenceState = ReferenceImageState.none,
    required this.onAddReference,
  });

  @override
  Widget build(BuildContext context) {
    const dockHeight = 104.0;

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: dockHeight + 6),
            child: Row(
              children: [
                SizedBox(
                  width: 190,
                  child: QuickStyleRail(
                    mode: mode,
                    status: status,
                    onStyleSelected: onStyleSelected,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HeroCanvasSection(
                    mode: mode,
                    status: status,
                    compareEnabled: compareEnabled,
                    compareSplit: compareSplit,
                    onCompareSplitChanged: onCompareSplitChanged,
                    beforeImage: beforeImage,
                    afterImage: afterImage,
                    emptyCanvas: emptyCanvas,
                  ),
                ),
                const SizedBox(width: 12),
                ActiveContextPanelHost(
                  mode: mode,
                  activePanel: activePanel,
                  status: status,
                  presentation: ContextPanelPresentation.sideInspector,
                  onClosePanel: () => onActivePanelChanged(UnifiedContextPanel.none),
                  onRequestExport: onRequestExport,
                  onRequestSave: onRequestSave,
                  onRequestShare: onRequestShare,
                  showAdvancedInspector: showAdvancedInspector,
                  referenceState: referenceState,
                  onAddReference: onAddReference,
                ),
              ],
            ),
          ),
        ),
        WorkspaceAdaptiveDock(
          mode: mode,
          activeDock: activeDock,
          height: dockHeight,
          onDockTapped: onDockTapped,
        ),
      ],
    );
  }
}

class WideWorkspaceLayout extends StatelessWidget {
  final UnifiedEditorMode mode;
  final UnifiedDockAction activeDock;
  final UnifiedContextPanel activePanel;

  final bool showAdvancedInspector;
  final UnifiedEditorStatus status;

  final bool compareEnabled;
  final double compareSplit;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  final ValueChanged<UnifiedDockAction> onDockTapped;
  final ValueChanged<double> onCompareSplitChanged;
  final ValueChanged<UnifiedContextPanel> onActivePanelChanged;
  final ValueChanged<String> onStyleSelected;
  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;
  final VoidCallback onAdvancedInspectorToggle;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;

  const WideWorkspaceLayout({
    super.key,
    required this.mode,
    required this.activeDock,
    required this.activePanel,
    required this.showAdvancedInspector,
    required this.status,
    required this.compareEnabled,
    required this.compareSplit,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
    required this.onDockTapped,
    required this.onCompareSplitChanged,
    required this.onActivePanelChanged,
    required this.onStyleSelected,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.onAdvancedInspectorToggle,
    this.referenceState = ReferenceImageState.none,
    required this.onAddReference,
  });

  @override
  Widget build(BuildContext context) {
    const dockHeight = 118.0;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 12, right: 12, bottom: dockHeight + 8),
          child: Row(
            children: [
              SizedBox(
                width: 190,
                child: QuickStyleRail(
                  mode: mode,
                  status: status,
                  onStyleSelected: onStyleSelected,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: HeroCanvasSection(
                  mode: mode,
                  status: status,
                  compareEnabled: compareEnabled,
                  compareSplit: compareSplit,
                  onCompareSplitChanged: onCompareSplitChanged,
                  beforeImage: beforeImage,
                  afterImage: afterImage,
                  emptyCanvas: emptyCanvas,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 420,
                child: Column(
                  children: [
                    Expanded(
                      child: ActiveContextPanelHost(
                        mode: mode,
                        activePanel: activePanel,
                        status: status,
                        presentation: ContextPanelPresentation.sideInspector,
                        onClosePanel: () => onActivePanelChanged(UnifiedContextPanel.none),
                        onRequestExport: onRequestExport,
                        onRequestSave: onRequestSave,
                        onRequestShare: onRequestShare,
                        showAdvancedInspector: showAdvancedInspector,
                        referenceState: referenceState,
                        onAddReference: onAddReference,
                      ),
                    ),
                    SizedBox(
                      height: showAdvancedInspector ? 300 : 92,
                      child: AdvancedInspector(
                        mode: mode,
                        status: status,
                        expanded: showAdvancedInspector,
                        onToggle: onAdvancedInspectorToggle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Dock anchored at bottom center.
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: WorkspaceAdaptiveDock(
            mode: mode,
            activeDock: activeDock,
            height: dockHeight,
            onDockTapped: onDockTapped,
          ),
        ),
      ],
    );
  }
}

