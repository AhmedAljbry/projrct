import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:untitled2/core/ui/AppTokens.dart';

import 'quick_style_rail.dart';
import 'workspace_adaptive_dock.dart';
import 'unified_editor_workspace.dart';
import 'reference_image_state.dart'; // ADDED THIS
import 'active_context_panel_host.dart'; // ADDED THIS

enum _SheetTab { styles, tools }

class WorkspaceBottomSheet extends StatefulWidget {
  final UnifiedEditorMode mode;
  final UnifiedEditorStatus status;
  final UnifiedDockAction activeDock;
  final UnifiedContextPanel activePanel; // ADDED THIS
  final ValueChanged<String> onStyleSelected;
  final ValueChanged<UnifiedDockAction> onDockTapped;
  final ValueChanged<UnifiedContextPanel> onActivePanelChanged; // ADDED THIS
  final bool compareEnabled;

  final VoidCallback onRequestExport;
  final VoidCallback onRequestSave;
  final VoidCallback onRequestShare;
  final bool showAdvancedInspector;
  final ReferenceImageState referenceState;
  final VoidCallback onAddReference;
  final VoidCallback onAdvancedInspectorToggle;

  const WorkspaceBottomSheet({
    super.key,
    required this.mode,
    required this.status,
    required this.activeDock,
    required this.activePanel,
    required this.onStyleSelected,
    required this.onDockTapped,
    required this.onActivePanelChanged,
    required this.compareEnabled,
    required this.onRequestExport,
    required this.onRequestSave,
    required this.onRequestShare,
    required this.showAdvancedInspector,
    this.referenceState = ReferenceImageState.none,
    required this.onAddReference,
    required this.onAdvancedInspectorToggle,
  });

  @override
  State<WorkspaceBottomSheet> createState() => _WorkspaceBottomSheetState();
}

class _WorkspaceBottomSheetState extends State<WorkspaceBottomSheet> {
  bool _expanded = false;
  _SheetTab _activeTab = _SheetTab.styles;

  void _toggleExpanded() {
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _setTab(_SheetTab tab) {
    setState(() {
      _activeTab = tab;
      if (!_expanded) _expanded = true; // Auto-expand when a tab is tapped.
    });
  }



  @override
  Widget build(BuildContext context) {
    // If a tool panel is active, force expansion to show it.
    final bool isPanelActive = widget.activePanel != UnifiedContextPanel.none;
    final bool effectivelyExpanded = _expanded || isPanelActive;

    // Height: Peek (collapsed) is 65px. Expanded provides enough room for grids or active panels.
    final double targetHeight = effectivelyExpanded ? 380.0 : 65.0;

    return GestureDetector(
      onVerticalDragUpdate: (details) {
        if (details.delta.dy < -4 && !_expanded) _toggleExpanded();
        if (details.delta.dy > 4 && _expanded && !isPanelActive) _toggleExpanded();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: targetHeight,
        decoration: BoxDecoration(
          color: AppTokens.surface.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: AppTokens.border.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 24,
              offset: const Offset(0, -6),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              children: [
                // Minimal Drag Handle
                GestureDetector(
                  onTap: _toggleExpanded,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    height: 16, // Reduced from 24 to fit inside 65.0 peek height
                    alignment: Alignment.center,
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTokens.text2.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                // Content Area: Crossfade entirely between (Tabs + Grids) and (ActivePanel)
                Expanded(
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 280),
                    crossFadeState: isPanelActive ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    layoutBuilder: (topChild, topKey, bottomChild, bottomKey) {
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.topCenter,
                        children: [
                          Positioned(
                            key: bottomKey,
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: bottomChild,
                          ),
                          Positioned(
                            key: topKey,
                            top: 0,
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: topChild,
                          ),
                        ],
                      );
                    },
                    firstChild: Column(
                      children: [
                        // Elegant Tabs (always visible in peek mode)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                          child: Container(
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppTokens.card.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTokens.border.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _TabButton(
                                    title: 'Styles',
                                    icon: Icons.auto_awesome_rounded,
                                    isActive: _activeTab == _SheetTab.styles,
                                    onTap: () => _setTab(_SheetTab.styles),
                                  ),
                                ),
                                Expanded(
                                  child: _TabButton(
                                    title: 'Tools',
                                    icon: Icons.tune_rounded,
                                    isActive: _activeTab == _SheetTab.tools,
                                    onTap: () => _setTab(_SheetTab.tools),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: AnimatedOpacity(
                            opacity: effectivelyExpanded ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 240),
                            child: IgnorePointer(
                              ignoring: !effectivelyExpanded,
                              child: SingleChildScrollView(
                                physics: const NeverScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: AnimatedCrossFade(
                                    duration: const Duration(milliseconds: 250),
                                    crossFadeState: _activeTab == _SheetTab.styles
                                        ? CrossFadeState.showFirst
                                        : CrossFadeState.showSecond,
                                    firstChild: _buildStylesContent(),
                                    secondChild: _buildToolsContent(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    secondChild: isPanelActive
                        ? ActiveContextPanelHost(
                            key: ValueKey(widget.activePanel),
                            mode: widget.mode,
                            activePanel: widget.activePanel,
                            status: widget.status,
                            presentation: ContextPanelPresentation.embeddedMobileSheet,
                            onClosePanel: () => widget.onActivePanelChanged(UnifiedContextPanel.none),
                            onRequestExport: widget.onRequestExport,
                            onRequestSave: widget.onRequestSave,
                            onRequestShare: widget.onRequestShare,
                            showAdvancedInspector: widget.showAdvancedInspector,
                            includeAdvancedInspector: true,
                            referenceState: widget.referenceState,
                            onAddReference: widget.onAddReference,
                            onAdvancedInspectorToggle: widget.onAdvancedInspectorToggle,
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStylesContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 250, // Enough height for the grid
          child: Align(
            alignment: Alignment.centerLeft,
            child: QuickStyleRail(
              mode: widget.mode,
              status: widget.status,
              onStyleSelected: widget.onStyleSelected,
              isGrid: true, // ADDED THIS
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToolsContent() {
    return Column(
      children: [
        SizedBox(
          height: 250, // Enough height for the grid
          child: WorkspaceAdaptiveDock(
            mode: widget.mode,
            activeDock: widget.activeDock,
            compareEnabled: widget.compareEnabled,
            isGrid: true, // ADDED THIS
            onDockTapped: (d) {
              widget.onDockTapped(d);
              // Do NOT dismiss sheet. Let the ActivePanel fade in instead.
            },
          ),
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? AppTokens.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? AppTokens.primary.withValues(alpha: 0.35) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isActive ? AppTokens.primary : AppTokens.text2,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isActive ? AppTokens.primary : AppTokens.text2,
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
