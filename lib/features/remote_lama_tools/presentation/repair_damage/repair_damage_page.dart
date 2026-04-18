import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:untitled2/core/background/presentation/pages/operations_page.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_manual_mask_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_action_bar.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_ai_tools.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_canvas.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_manual_tools.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/widgets/repair_damage_mode_switcher.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_status_indicator.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/entities/retouch_mask_assist_models.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/repair_mask_assist_cubit.dart';

class RepairDamagePage extends StatefulWidget {
  const RepairDamagePage({super.key});

  @override
  State<RepairDamagePage> createState() => _RepairDamagePageState();
}

class _RepairDamagePageState extends State<RepairDamagePage> {
  static const double _manualBrushRadiusMin = 6;
  static const double _manualBrushRadiusMax = 120;
  static const double _aiBrushRadiusMin = 8;
  static const double _aiBrushRadiusMax = 128;

  ui.Image? _decodedUiImage;
  Uint8List? _sourceBytes;
  double _manualBrushRadius = 20;
  double _aiBrushRadius = 28;
  bool _manualAdvancedExpanded = false;
  bool _aiAdvancedExpanded = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<RepairDamageCubit>().state;
    if (state is RepairDamageReady) {
      _sourceBytes = state.imageBytes;
      _decodeImage(state.imageBytes);
    }
  }

  @override
  void dispose() {
    _decodedUiImage?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) {
      return;
    }

    final bytes = await xfile.readAsBytes();
    await _loadEditingImage(bytes);
  }

  Future<void> _loadEditingImage(Uint8List bytes) async {
    await _decodeImage(bytes);
    if (!mounted) {
      return;
    }

    await Future.wait([
      context.read<RepairDamageManualMaskCubit>().setImage(bytes),
      context.read<RepairMaskAssistCubit>().setImage(bytes, resetMode: false),
    ]);

    if (!mounted) {
      return;
    }

    setState(() {
      _sourceBytes = bytes;
      _manualAdvancedExpanded = false;
      _aiAdvancedExpanded = false;
    });

    context.read<RepairDamageCubit>().setImage(bytes);
  }

  Future<void> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) {
      frame.image.dispose();
      return;
    }

    setState(() {
      _decodedUiImage?.dispose();
      _decodedUiImage = frame.image;
    });
  }

  bool _assistHasMaskContent(RepairMaskAssistState state) {
    return state.maskAlpha?.any((value) => value > 0) ?? false;
  }

  Future<void> _submit(
    BuildContext context, {
    required MaskCreationMode mode,
    required RepairDamageManualMaskState manualState,
    required RepairMaskAssistState assistState,
    required bool assistHasMaskContent,
  }) async {
    Uint8List? maskBytes;

    if (mode == MaskCreationMode.manual) {
      if (!manualState.hasMaskContent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mask the damaged area before applying repair.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      maskBytes =
          await context.read<RepairDamageManualMaskCubit>().exportMaskPng();
    } else {
      if (!assistHasMaskContent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Generate or refine an AI assist mask before applying repair.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      maskBytes = await context.read<RepairMaskAssistCubit>().exportMaskPng();
    }

    if (maskBytes == null || !context.mounted) {
      return;
    }

    context.read<RepairDamageCubit>().submitJob(maskBytes);
  }

  void _resetSession() {
    setState(() {
      _sourceBytes = null;
      _decodedUiImage?.dispose();
      _decodedUiImage = null;
      _manualAdvancedExpanded = false;
      _aiAdvancedExpanded = false;
    });

    context.read<RepairDamageCubit>().reset();
    context.read<RepairDamageManualMaskCubit>().reset();
    context
        .read<RepairMaskAssistCubit>()
        .setCreationMode(MaskCreationMode.manual);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RepairDamageCubit, RepairDamageState>(
      listener: (context, state) {
        if (state is RepairDamageFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              action: state.isRetryable
                  ? SnackBarAction(
                      label: 'Dismiss',
                      textColor: Colors.white,
                      onPressed: () {},
                    )
                  : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final isBusy =
            state is RepairDamageSubmitting || state is RepairDamageProcessing;

        return Scaffold(
          backgroundColor: LamaTheme.background,
          appBar: AppBar(
            backgroundColor: LamaTheme.toolbarBg,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.go('/editor'),
            ),
            title: const Text(
              'Repair Damage',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              IconButton(
                onPressed: () => _pickImage(context),
                icon: const Icon(Icons.add_photo_alternate_outlined),
                tooltip: 'Import image',
              ),
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OperationsPage()),
                ),
                icon: const Icon(Icons.dashboard_customize_rounded),
                tooltip: 'Operations',
              ),
            ],
          ),
          body: Stack(
            children: [
              SafeArea(
                bottom: false,
                child: _buildMainContent(context, state),
              ),
              if (isBusy)
                LamaStatusIndicator(
                  progress: state is RepairDamageProcessing
                      ? state.status.progress
                      : 0,
                  message: state is RepairDamageProcessing
                      ? state.status.message
                      : 'Uploading...',
                  isProcessing: state is RepairDamageProcessing,
                  onOpenOperations: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OperationsPage()),
                  ),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomActionBar(state),
        );
      },
    );
  }

  Widget? _buildBottomActionBar(RepairDamageState state) {
    final hasEditorSession = _sourceBytes != null &&
        _decodedUiImage != null &&
        state is! RepairDamageSuccess;

    if (!hasEditorSession) {
      return null;
    }

    final isBusy =
        state is RepairDamageSubmitting || state is RepairDamageProcessing;

    return BlocBuilder<RepairMaskAssistCubit, RepairMaskAssistState>(
      builder: (context, assistState) {
        return BlocBuilder<RepairDamageManualMaskCubit,
            RepairDamageManualMaskState>(
          builder: (context, manualState) {
            final mode = assistState.creationMode;
            final assistHasMaskContent = _assistHasMaskContent(assistState);
            final canApply = mode == MaskCreationMode.manual
                ? manualState.hasMaskContent
                : assistHasMaskContent;

            return RepairDamageActionBar(
              canApply: canApply,
              isBusy: isBusy,
              onApply: () => _submit(
                context,
                mode: mode,
                manualState: manualState,
                assistState: assistState,
                assistHasMaskContent: assistHasMaskContent,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMainContent(BuildContext context, RepairDamageState state) {
    if (state is RepairDamageSuccess) {
      return LamaResultViewer(
        resultBytes: state.resultBytes,
        originalBytes: _sourceBytes,
        onReset: _resetSession,
      );
    }

    if (_sourceBytes == null || _decodedUiImage == null) {
      return Center(
        child: FilledButton.icon(
          onPressed: () => _pickImage(context),
          style: FilledButton.styleFrom(
            backgroundColor: LamaTheme.accent,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          icon: const Icon(Icons.add_photo_alternate_rounded),
          label: const Text(
            'Select Image',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      );
    }

    return BlocBuilder<RepairMaskAssistCubit, RepairMaskAssistState>(
      builder: (context, assistState) {
        return BlocBuilder<RepairDamageManualMaskCubit,
            RepairDamageManualMaskState>(
          builder: (context, manualState) {
            final mode = assistState.creationMode;
            final assistHasMaskContent = _assistHasMaskContent(assistState);
            final previewOverlay = mode == MaskCreationMode.manual
                ? (manualState.previewVisible
                    ? manualState.maskPreviewPng
                    : null)
                : (assistState.previewVisible
                    ? assistState.maskPreviewPng
                    : null);
            final editMode = mode == MaskCreationMode.manual
                ? manualState.editMode
                : assistState.editMode;
            final brushRadius = mode == MaskCreationMode.manual
                ? _manualBrushRadius
                : _aiBrushRadius;
            final drawingEnabled = mode == MaskCreationMode.manual
                ? manualState.isReady
                : assistState.hasSuggestion;
            return LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding =
                    constraints.maxWidth >= 900 ? 24.0 : 16.0;
                final toolPanelMaxHeight =
                    math.min(280.0, constraints.maxHeight * 0.33);

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        16,
                        horizontalPadding,
                        12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: RepairDamageModeSwitcher(
                              mode: assistState.creationMode,
                              onChanged: (mode) => context
                                  .read<RepairMaskAssistCubit>()
                                  .setCreationMode(mode),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Center(
                              child: AspectRatio(
                                aspectRatio: _decodedUiImage!.width /
                                    _decodedUiImage!.height,
                                child: RepairDamageCanvas(
                                  image: _decodedUiImage!,
                                  previewOverlayPng: previewOverlay,
                                  editMode: editMode,
                                  brushRadiusImage: brushRadius,
                                  drawingEnabled: drawingEnabled,
                                  onStrokeCommitted: (imagePoints) async {
                                    if (mode == MaskCreationMode.manual) {
                                      await context
                                          .read<RepairDamageManualMaskCubit>()
                                          .commitStroke(
                                            imagePoints: imagePoints,
                                            brushRadius: _manualBrushRadius,
                                          );
                                      return;
                                    }

                                    await context
                                        .read<RepairMaskAssistCubit>()
                                        .commitStroke(
                                          imagePoints: imagePoints,
                                          brushRadius: _aiBrushRadius,
                                        );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: toolPanelMaxHeight,
                              minHeight: 144,
                            ),
                            child: _buildToolPanel(
                              mode: mode,
                              manualState: manualState,
                              assistState: assistState,
                              assistHasMaskContent: assistHasMaskContent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildToolPanel({
    required MaskCreationMode mode,
    required RepairDamageManualMaskState manualState,
    required RepairMaskAssistState assistState,
    required bool assistHasMaskContent,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: LamaTheme.toolbarBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: mode == MaskCreationMode.manual
              ? RepairDamageManualTools(
                  key: const ValueKey('repair-manual-tools'),
                  state: manualState,
                  brushRadius: _manualBrushRadius,
                  advancedExpanded: _manualAdvancedExpanded,
                  onAdvancedExpandedChanged: (value) {
                    setState(() => _manualAdvancedExpanded = value);
                  },
                  onEditModeChanged: (mode) => context
                      .read<RepairDamageManualMaskCubit>()
                      .setEditMode(mode),
                  onBrushRadiusChanged: (value) {
                    setState(() {
                      _manualBrushRadius = value.clamp(
                        _manualBrushRadiusMin,
                        _manualBrushRadiusMax,
                      );
                    });
                  },
                  onFeatherChanged: (value) => context
                      .read<RepairDamageManualMaskCubit>()
                      .updateFeather(value),
                  onUndo: () =>
                      context.read<RepairDamageManualMaskCubit>().undo(),
                  onRedo: () =>
                      context.read<RepairDamageManualMaskCubit>().redo(),
                  onExpand: () => context
                      .read<RepairDamageManualMaskCubit>()
                      .transformMask(MaskTransformAction.expand),
                  onContract: () => context
                      .read<RepairDamageManualMaskCubit>()
                      .transformMask(MaskTransformAction.contract),
                  onClear: () =>
                      context.read<RepairDamageManualMaskCubit>().clearMask(),
                  onPreviewChanged: (value) => context
                      .read<RepairDamageManualMaskCubit>()
                      .togglePreview(value),
                )
              : RepairDamageAiTools(
                  key: const ValueKey('repair-ai-tools'),
                  state: assistState,
                  hasMaskContent: assistHasMaskContent,
                  brushRadius: _aiBrushRadius,
                  advancedExpanded: _aiAdvancedExpanded,
                  onAdvancedExpandedChanged: (value) {
                    setState(() => _aiAdvancedExpanded = value);
                  },
                  onGenerate: () => context
                      .read<RepairMaskAssistCubit>()
                      .generateSuggestion(),
                  onRetry: () =>
                      context.read<RepairMaskAssistCubit>().retrySuggestion(),
                  onEditModeChanged: (mode) =>
                      context.read<RepairMaskAssistCubit>().setEditMode(mode),
                  onBrushRadiusChanged: (value) {
                    setState(() {
                      _aiBrushRadius =
                          value.clamp(_aiBrushRadiusMin, _aiBrushRadiusMax);
                    });
                  },
                  onFeatherChanged: (value) => context
                      .read<RepairMaskAssistCubit>()
                      .updateFeather(value),
                  onExpand: () => context
                      .read<RepairMaskAssistCubit>()
                      .transformMask(MaskTransformAction.expand),
                  onContract: () => context
                      .read<RepairMaskAssistCubit>()
                      .transformMask(MaskTransformAction.contract),
                  onClear: () =>
                      context.read<RepairMaskAssistCubit>().clearMask(),
                  onUndo: () => context.read<RepairMaskAssistCubit>().undo(),
                  onRedo: () => context.read<RepairMaskAssistCubit>().redo(),
                  onPreviewChanged: (value) => context
                      .read<RepairMaskAssistCubit>()
                      .togglePreview(value),
                ),
        ),
      ),
    );
  }
}
