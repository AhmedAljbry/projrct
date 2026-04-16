import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../domain/entities/editor_models.dart';
import '../controllers/ai_object_copy_paste_controller.dart';
import '../widgets/editor_canvas.dart';

class AiObjectCopyPastePage extends StatefulWidget {
  const AiObjectCopyPastePage({super.key});

  @override
  State<AiObjectCopyPastePage> createState() => _AiObjectCopyPastePageState();
}

class _AiObjectCopyPastePageState extends State<AiObjectCopyPastePage> {
  late final AiObjectCopyPasteController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AiObjectCopyPasteController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme =
        GoogleFonts.spaceGroteskTextTheme(Theme.of(context).textTheme);
    return Theme(
      data: Theme.of(context).copyWith(textTheme: textTheme),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              child: Column(
                children: [
                  _TopToolbar(
                    controller: _controller,
                    onOpenResult: _openResultPreview,
                  ),
                  Container(height: 1, color: Colors.white10),
                  Expanded(
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
                          child: EditorCanvas(controller: _controller),
                        ),
                        Positioned(
                          top: 14,
                          left: 14,
                          right: 112,
                          child: _HintBubble(message: state.statusMessage),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: _FloatingAssetRail(controller: _controller),
                        ),
                        if (state.isBusy)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.35),
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 14),
                                decoration: BoxDecoration(
                                  color: const Color(0xDD121212),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: const Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 26,
                                      height: 26,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.4,
                                        color: Color(0xFF63D5A3),
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Preparing patch...',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  _BottomToolRail(controller: _controller),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopToolbar extends StatelessWidget {
  const _TopToolbar({required this.controller});

  final AiObjectCopyPasteController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
      child: Row(
        children: [
          _TopIconButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.of(context).pop()),
          const SizedBox(width: 10),
          _ModeBadge(controller: controller),
          const SizedBox(width: 10),
          _TopIconButton(
              icon: Icons.undo_rounded,
              onTap: state.canUndo ? controller.undo : null),
          const SizedBox(width: 8),
          _TopIconButton(
              icon: Icons.redo_rounded,
              onTap: state.canRedo ? controller.redo : null),
          const SizedBox(width: 8),
          _TopIconButton(
              icon: Icons.layers_rounded, onTap: controller.toggleLayers),
          const SizedBox(width: 8),
          _TopIconButton(
            icon: Icons.download_rounded,
            onTap:
                state.isExporting ? null : () => controller.exportComposition(),
            foregroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.controller});

  final AiObjectCopyPasteController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final active =
        state.activeRole == ActiveDocumentRole.target ? 'Target' : 'Source';
    return GestureDetector(
      onTap: () {
        if (state.hasDualDocument) {
          controller.setActiveRole(
            state.activeRole == ActiveDocumentRole.source
                ? ActiveDocumentRole.target
                : ActiveDocumentRole.source,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF111214),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_all_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              active,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingAssetRail extends StatelessWidget {
  const _FloatingAssetRail({required this.controller});

  final AiObjectCopyPasteController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final previewItems = <PastedItem>[
      if (state.pendingItem != null) state.pendingItem!,
      ...state.items.reversed.take(3),
    ];
    return Column(
      children: [
        GestureDetector(
          onTap: state.sourceDocument == null
              ? controller.importSourceImage
              : controller.importTargetImage,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF63D5A3),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF63D5A3).withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 14),
        _ThumbTile(
          image: state.sourceDocument?.preview,
          selected: state.activeRole == ActiveDocumentRole.source,
          icon: Icons.photo_camera_rounded,
          onTap: state.sourceDocument == null
              ? controller.importSourceImage
              : () => controller.setActiveRole(ActiveDocumentRole.source),
        ),
        const SizedBox(height: 12),
        _ThumbTile(
          image: state.hasDualDocument ? state.targetDocument?.preview : null,
          selected: state.activeRole == ActiveDocumentRole.target,
          icon: Icons.layers_clear_rounded,
          onTap: state.hasDualDocument
              ? () => controller.setActiveRole(ActiveDocumentRole.target)
              : controller.importTargetImage,
        ),
        if (state.showLayers) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 88,
            child: Column(
              children: previewItems.map((item) {
                final selected = item.id == state.selectedItemId;
                final isPending = state.pendingItem?.id == item.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => controller.selectItem(item.id),
                    child: Container(
                      width: 88,
                      height: 72,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF121212),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isPending
                              ? const Color(0xFF63D5A3)
                              : (selected
                                  ? const Color(0xFFE287FF)
                                  : Colors.white10),
                          width: selected || isPending ? 1.5 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: RawImage(
                                image: item.clipboard.preview,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                              ),
                            ),
                          ),
                          if (isPending)
                            Positioned(
                              left: 4,
                              top: 4,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF63D5A3),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Preview',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({
    required this.image,
    required this.selected,
    required this.icon,
    required this.onTap,
  });

  final ui.Image? image;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 88,
        height: 88,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFF111214),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? const Color(0xFF63D5A3) : Colors.white10,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: image == null
              ? ColoredBox(
                  color: const Color(0xFF1A1A1A),
                  child: Icon(icon, color: Colors.white54, size: 28),
                )
              : RawImage(
                  image: image,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                ),
        ),
      ),
    );
  }
}

class _HintBubble extends StatelessWidget {
  const _HintBubble({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xDD121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Text(
        message!,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white70, fontSize: 12.5),
      ),
    );
  }
}

class _BottomToolRail extends StatelessWidget {
  const _BottomToolRail({required this.controller});

  final AiObjectCopyPasteController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state;
    final hasSelection = state.selection != null;
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 18),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _BottomAction(
              icon: Icons.crop_square_rounded,
              label: 'Select',
              selected: state.interactionMode ==
                  CanvasInteractionMode.selectRectangle,
              onTap: () => controller
                  .setInteractionMode(CanvasInteractionMode.selectRectangle),
            ),
            _BottomAction(
              icon: Icons.gesture_rounded,
              label: 'Lasso',
              selected:
                  state.interactionMode == CanvasInteractionMode.selectLasso,
              onTap: () => controller
                  .setInteractionMode(CanvasInteractionMode.selectLasso),
            ),
            _BottomAction(
              icon: Icons.auto_awesome_rounded,
              label: 'Smart',
              selected: state.interactionMode == CanvasInteractionMode.smartTap,
              onTap: controller.enterSmartSelectionMode,
            ),
            _BottomAction(
              icon: Icons.person_search_rounded,
              label: 'People',
              selected:
                  state.interactionMode == CanvasInteractionMode.smartPersonTap,
              onTap: controller.enterPeopleSelectionMode,
            ),
            _BottomAction(
              icon: Icons.check_rounded,
              label: 'Confirm',
              enabled: controller.canConfirm,
              onTap: controller.commitSelectionEdit,
            ),
            _BottomAction(
              icon: Icons.copy_rounded,
              label: 'Copy',
              enabled: hasSelection,
              onTap: controller.copySelection,
            ),
            _BottomAction(
              icon: Icons.content_paste_rounded,
              label: 'Paste',
              enabled: controller.canPaste,
              onTap: controller.pasteClipboard,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final foreground = !enabled
        ? Colors.white24
        : (selected ? const Color(0xFFE287FF) : Colors.white);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: 72,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: foreground.withValues(alpha: 0.9), width: 1.5),
                  color:
                      selected ? const Color(0x22E287FF) : Colors.transparent,
                ),
                child: Icon(icon, color: foreground, size: 30),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: foreground,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    required this.onTap,
    this.foregroundColor = Colors.white,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF111214),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Icon(icon,
            color: onTap == null ? Colors.white24 : foregroundColor, size: 30),
      ),
    );
  }
}

