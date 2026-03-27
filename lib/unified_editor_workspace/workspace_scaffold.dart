import 'package:flutter/material.dart';
import 'package:untitled2/core/utils/Responsive.dart';

import 'reference_image_chip.dart';
import 'reference_image_state.dart';
import 'unified_editor_workspace.dart';
import 'workspace_top_bar.dart';
import 'workspace_mode_switcher.dart';
import 'workspace_status_strip.dart';
import 'responsive_layouts.dart';

class WorkspaceScaffold extends StatelessWidget {
  final UnifiedEditorMode mode;
  final ValueChanged<UnifiedEditorMode> onModeChanged;
  final String title;
  final UnifiedEditorStatus status;

  final UnifiedDockAction activeDock;
  final UnifiedContextPanel activePanel;

  final bool showAdvancedInspector;

  final bool compareEnabled;
  final double compareSplit;

  final ImageProvider? beforeImage;
  final ImageProvider? afterImage;
  final Widget? emptyCanvas;

  final ValueChanged<UnifiedDockAction> onDockTapped;
  final VoidCallback onCompareToggled;
  final VoidCallback onAdvancedInspectorToggle;
  final ValueChanged<double> onCompareSplitChanged;

  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;
  final ValueChanged<UnifiedContextPanel> onActivePanelChanged;
  final ValueChanged<String> onStyleSelected;

  // Reference Image
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;
  final VoidCallback onClearReference;

  const WorkspaceScaffold({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.title,
    required this.status,
    required this.activeDock,
    required this.activePanel,
    required this.showAdvancedInspector,
    required this.compareEnabled,
    required this.compareSplit,
    required this.beforeImage,
    required this.afterImage,
    required this.emptyCanvas,
    required this.onDockTapped,
    required this.onStyleSelected,
    required this.onCompareToggled,
    required this.onAdvancedInspectorToggle,
    required this.onCompareSplitChanged,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.onActivePanelChanged,
    required this.referenceState,
    required this.onAddReference,
    required this.onClearReference,
  });

  @override
  Widget build(BuildContext context) {
    final device = Responsive.of(context);

    final topBar = WorkspaceTopBar(
      title: title,
      mode: mode,
      onCompareTapped: onCompareToggled,
      compareActive: status.compareActive,
      onSaveTapped: onRequestSave,
      onExportTapped: onRequestExport,
      onAdvancedInspectorTapped: onAdvancedInspectorToggle,
      referenceActive: referenceState.hasReference,
      onAddReferenceTapped: onAddReference,
    );

    final modeSwitcher = WorkspaceModeSwitcher(
      mode: mode,
      onChanged: onModeChanged,
    );

    final statusStrip = WorkspaceStatusStrip(status: status, mode: mode);

    // Reference chip sits between top bar and mode switcher
    final referenceChip = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          ReferenceImageChip(
            refState: referenceState,
            onClear: onClearReference,
            onReplace: onAddReference,
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF08141B),
          ),
          child: Column(
            children: [
              topBar,
              referenceChip,
              modeSwitcher,
              statusStrip,
              Expanded(
                child: device == DeviceType.phone
                    ? MobileWorkspaceLayout(
                        mode: mode,
                        activeDock: activeDock,
                        activePanel: activePanel,
                        showAdvancedInspector: showAdvancedInspector,
                        status: status,
                        compareEnabled: compareEnabled,
                        compareSplit: compareSplit,
                        beforeImage: beforeImage,
                        afterImage: afterImage,
                        emptyCanvas: emptyCanvas,
                        onDockTapped: onDockTapped,
                        onStyleSelected: onStyleSelected,
                        onCompareSplitChanged: onCompareSplitChanged,
                        onCompareToggled: onCompareToggled, // ADDED
                        onActivePanelChanged: onActivePanelChanged,
                        onRequestExport: onRequestExport,
                        onRequestSave: onRequestSave,
                        onRequestShare: onRequestShare,
                        onAdvancedInspectorToggle: onAdvancedInspectorToggle,
                        referenceState: referenceState,
                        onAddReference: onAddReference,
                      )
                    : device == DeviceType.tablet
                        ? TabletWorkspaceLayout(
                            mode: mode,
                            activeDock: activeDock,
                            activePanel: activePanel,
                            showAdvancedInspector: showAdvancedInspector,
                            status: status,
                            compareEnabled: compareEnabled,
                            compareSplit: compareSplit,
                            beforeImage: beforeImage,
                            afterImage: afterImage,
                            emptyCanvas: emptyCanvas,
                            onDockTapped: onDockTapped,
                            onStyleSelected: onStyleSelected,
                            onCompareSplitChanged: onCompareSplitChanged,
                            onCompareToggled: onCompareToggled, // ADDED
                            onActivePanelChanged: onActivePanelChanged,
                            onRequestExport: onRequestExport,
                            onRequestSave: onRequestSave,
                            onRequestShare: onRequestShare,
                            onAdvancedInspectorToggle: onAdvancedInspectorToggle,
                            referenceState: referenceState,
                            onAddReference: onAddReference,
                          )
                        : WideWorkspaceLayout(
                            mode: mode,
                            activeDock: activeDock,
                            activePanel: activePanel,
                            showAdvancedInspector: showAdvancedInspector,
                            status: status,
                            compareEnabled: compareEnabled,
                            compareSplit: compareSplit,
                            beforeImage: beforeImage,
                            afterImage: afterImage,
                            emptyCanvas: emptyCanvas,
                            onDockTapped: onDockTapped,
                            onStyleSelected: onStyleSelected,
                            onCompareSplitChanged: onCompareSplitChanged,
                            onCompareToggled: onCompareToggled, // ADDED
                            onActivePanelChanged: onActivePanelChanged,
                            onRequestExport: onRequestExport,
                            onRequestSave: onRequestSave,
                            onRequestShare: onRequestShare,
                            onAdvancedInspectorToggle: onAdvancedInspectorToggle,
                            referenceState: referenceState,
                            onAddReference: onAddReference,
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

