import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/features/export/data/style_transfer_export_service.dart';
import 'package:untitled2/features/presets/data/shared_prefs_style_preset_repository.dart';
import 'package:untitled2/features/presets/domain/repositories/style_preset_repository.dart';
import 'package:untitled2/features/style_transfer/application/style_transfer_state.dart';
import 'package:untitled2/features/style_transfer/data/models/style_seed_library.dart';
import 'package:untitled2/features/style_transfer/data/repositories/style_transfer_repository_impl.dart';
import 'package:untitled2/features/style_transfer/domain/entities/detail_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/hsl_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/local_rules.dart';
import 'package:untitled2/features/style_transfer/domain/entities/style_profile.dart';
import 'package:untitled2/features/style_transfer/domain/entities/tone_profile.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/analyze_scene_use_case.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/apply_style_use_case.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/batch_apply_use_case.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/extract_style_use_case.dart';
import 'package:untitled2/features/style_transfer/domain/usecases/save_preset_use_case.dart';

class StyleTransferController extends Cubit<StyleTransferState> {
  StyleTransferController({
    required ExtractStyleUseCase extractStyleUseCase,
    required AnalyzeSceneUseCase analyzeSceneUseCase,
    required ApplyStyleUseCase applyStyleUseCase,
    required BatchApplyUseCase batchApplyUseCase,
    required SavePresetUseCase savePresetUseCase,
    required StylePresetRepository presetRepository,
    required StyleTransferExportService exportService,
  })  : _extractStyleUseCase = extractStyleUseCase,
        _analyzeSceneUseCase = analyzeSceneUseCase,
        _applyStyleUseCase = applyStyleUseCase,
        _batchApplyUseCase = batchApplyUseCase,
        _savePresetUseCase = savePresetUseCase,
        _presetRepository = presetRepository,
        _exportService = exportService,
        super(
          StyleTransferState.initial(
            trendingStyles: StyleSeedLibrary.trendingStyles,
            library: StyleSeedLibrary.categorizedStyles,
          ),
        ) {
    unawaited(loadSavedPresets());
  }

  factory StyleTransferController.standard() {
    final repository = StyleTransferRepositoryImpl();
    final presetRepository = SharedPrefsStylePresetRepository();
    final applyStyle = ApplyStyleUseCase(repository);
    return StyleTransferController(
      extractStyleUseCase: ExtractStyleUseCase(repository),
      analyzeSceneUseCase: AnalyzeSceneUseCase(repository),
      applyStyleUseCase: applyStyle,
      batchApplyUseCase: BatchApplyUseCase(applyStyle),
      savePresetUseCase: SavePresetUseCase(presetRepository),
      presetRepository: presetRepository,
      exportService: const StyleTransferExportService(),
    );
  }

  final ExtractStyleUseCase _extractStyleUseCase;
  final AnalyzeSceneUseCase _analyzeSceneUseCase;
  final ApplyStyleUseCase _applyStyleUseCase;
  final BatchApplyUseCase _batchApplyUseCase;
  final SavePresetUseCase _savePresetUseCase;
  final StylePresetRepository _presetRepository;
  final StyleTransferExportService _exportService;

  Timer? _previewDebounce;
  int _previewTicket = 0;

  Future<void> loadSavedPresets() async {
    final presets = await _presetRepository.loadPresets();
    if (!isClosed) {
      emit(state.copyWith(savedPresets: presets));
    }
  }

  Future<void> setReferenceImage(Uint8List bytes, {String? name}) async {
    emit(state.copyWith(
      referenceBytes: bytes,
      referenceName: name ?? 'Reference image',
      isPreparing: true,
      errorMessage: null,
      statusMessage: 'Extracting style DNA...',
    ));
    try {
      final style = await _extractStyleUseCase(
          referenceBytes: bytes, name: name ?? 'Reference style');
      final analysis = await _analyzeSceneUseCase(bytes);
      if (isClosed) return;
      emit(state.copyWith(
        styleProfile: style,
        referenceAnalysis: analysis,
        isPreparing: false,
        statusMessage: 'Reference style ready.',
      ));
      _schedulePreviewRefresh(immediate: true);
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isPreparing: false,
          errorMessage:
              'Unable to extract style from the selected reference image.',
        ));
      }
    }
  }

  Future<void> useSeedStyle(StyleProfile profile) async {
    emit(state.copyWith(
      styleProfile: profile,
      referenceBytes: null,
      referenceName: profile.name,
      referenceAnalysis: null,
      exportResult: null,
      errorMessage: null,
      statusMessage: 'Preset style selected.',
    ));
    _schedulePreviewRefresh(immediate: true);
  }

  Future<void> setTargetImage(Uint8List bytes, {String? name}) async {
    emit(state.copyWith(
      targetBytes: bytes,
      targetName: name ?? 'Target image',
      isPreparing: true,
      errorMessage: null,
      statusMessage: 'Analyzing target scene...',
    ));
    try {
      final analysis = await _analyzeSceneUseCase(bytes);
      if (isClosed) return;
      emit(state.copyWith(
        targetAnalysis: analysis,
        isPreparing: false,
        statusMessage: 'Target scene analyzed.',
      ));
      _schedulePreviewRefresh(immediate: true);
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isPreparing: false,
          errorMessage: 'Unable to analyze the selected target image.',
        ));
      }
    }
  }

  Future<void> ensureReady() async {
    if (!state.canStart) {
      emit(state.copyWith(
          errorMessage: 'Select a target image and a reference style first.'));
      return;
    }
    if (state.previewResult == null && !state.isRenderingPreview) {
      await refreshPreview(force: true);
    }
  }

  void updateStrength(double value) {
    _updateSettings(state.settings.copyWith(strength: value));
  }

  void updateSceneFit(bool value) {
    _updateSettings(state.settings.copyWith(sceneFit: value));
  }

  void updateExposureLock(bool value) {
    _updateSettings(state.settings.copyWith(exposureLock: value));
  }

  void updateSkinProtect(bool value) {
    _updateSettings(
      state.settings.copyWith(
        localOverrides:
            state.settings.localOverrides.copyWith(skinProtect: value),
      ),
    );
  }

  void updateTone(ToneProfile Function(ToneProfile current) transform) {
    _updateSettings(
      state.settings.copyWith(
        toneAdjustment: transform(state.settings.toneAdjustment),
      ),
    );
  }

  void updateHslChannel(
      String channel, HslChannel Function(HslChannel current) transform) {
    final current = state.settings.hslAdjustment.channelByName(channel);
    _updateSettings(
      state.settings.copyWith(
        hslAdjustment: state.settings.hslAdjustment
            .withChannel(channel, transform(current)),
      ),
    );
  }

  void updateCurvePoint(String curveName, int index, double value) {
    List<double> write(List<double> curve) {
      final updated = List<double>.from(curve);
      if (index >= 0 && index < updated.length) {
        updated[index] = value;
      }
      return updated;
    }

    final current = state.settings.curveAdjustment;
    switch (curveName) {
      case 'master':
        _updateSettings(state.settings.copyWith(
            curveAdjustment: current.copyWith(master: write(current.master))));
        break;
      case 'red':
        _updateSettings(state.settings.copyWith(
            curveAdjustment: current.copyWith(red: write(current.red))));
        break;
      case 'green':
        _updateSettings(state.settings.copyWith(
            curveAdjustment: current.copyWith(green: write(current.green))));
        break;
      case 'blue':
        _updateSettings(state.settings.copyWith(
            curveAdjustment: current.copyWith(blue: write(current.blue))));
        break;
    }
  }

  void updateDetail(DetailProfile Function(DetailProfile current) transform) {
    _updateSettings(
      state.settings.copyWith(
        detailAdjustment: transform(state.settings.detailAdjustment),
      ),
    );
  }

  void updateMaskRules(LocalRules Function(LocalRules current) transform) {
    _updateSettings(
      state.settings
          .copyWith(localOverrides: transform(state.settings.localOverrides)),
    );
  }

  Future<void> refreshPreview({bool force = false}) async {
    if (!state.canStart) {
      return;
    }
    final ticket = ++_previewTicket;
    emit(state.copyWith(
      isRenderingPreview: true,
      errorMessage: null,
      exportResult: null,
      statusMessage: 'Rendering fast preview...',
    ));
    try {
      final result = await _applyStyleUseCase(
        targetBytes: state.targetBytes!,
        styleProfile: state.styleProfile!,
        settings: state.settings,
        referenceBytes: state.referenceBytes,
        targetAnalysis: state.targetAnalysis,
      );
      if (isClosed || ticket != _previewTicket) {
        return;
      }
      emit(state.copyWith(
        previewResult: result,
        targetAnalysis: result.sceneAnalysis,
        isRenderingPreview: false,
        statusMessage: result.usedCachedPreview
            ? 'Preview loaded from cache.'
            : 'Preview updated.',
      ));
    } catch (_) {
      if (!isClosed && (force || ticket == _previewTicket)) {
        emit(state.copyWith(
          isRenderingPreview: false,
          errorMessage:
              'Preview rendering failed. Try another image or lower intensity.',
        ));
      }
    }
  }

  Future<void> renderHighQuality() async {
    if (!state.canStart) {
      emit(state.copyWith(errorMessage: 'Preview the style first.'));
      return;
    }
    emit(state.copyWith(
      isRenderingExport: true,
      errorMessage: null,
      statusMessage: 'Rendering high-resolution export...',
    ));
    try {
      final result = await _applyStyleUseCase(
        targetBytes: state.targetBytes!,
        styleProfile: state.styleProfile!,
        settings: state.settings,
        referenceBytes: state.referenceBytes,
        targetAnalysis: state.targetAnalysis,
        highQuality: true,
      );
      if (isClosed) return;
      emit(state.copyWith(
        previewResult: result,
        exportResult: result,
        targetAnalysis: result.sceneAnalysis,
        isRenderingExport: false,
        statusMessage: 'High-resolution result is ready.',
      ));
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(
          isRenderingExport: false,
          errorMessage: 'High-resolution export failed.',
        ));
      }
    }
  }

  Future<void> saveCurrentPreset(String name) async {
    final source = state.previewResult?.appliedProfile ?? state.styleProfile;
    if (source == null) {
      emit(state.copyWith(errorMessage: 'No style is available to save yet.'));
      return;
    }
    final preset = source.copyWith(
      id: 'preset-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
    );
    await _savePresetUseCase(preset);
    await loadSavedPresets();
    if (!isClosed) {
      emit(
          state.copyWith(statusMessage: 'Preset saved to your style library.'));
    }
  }

  Future<void> deletePreset(String id) async {
    await _presetRepository.deletePreset(id);
    await loadSavedPresets();
    if (!isClosed) {
      emit(state.copyWith(
          statusMessage: 'Preset removed from your style library.'));
    }
  }

  Future<void> exportCurrent() async {
    var bytes = state.exportResult?.exportBytes;
    bytes ??= state.previewResult?.previewBytes;
    if (bytes == null) {
      emit(state.copyWith(errorMessage: 'Render a result before exporting.'));
      return;
    }
    if (state.exportResult == null) {
      await renderHighQuality();
      bytes =
          state.exportResult?.exportBytes ?? state.previewResult?.previewBytes;
    }
    if (bytes == null) {
      return;
    }
    await _exportService.saveToGallery(bytes,
        name: 'viral_style_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (!isClosed) {
      emit(state.copyWith(statusMessage: 'Image exported to your gallery.'));
    }
  }

  Future<void> shareCurrent() async {
    var bytes = state.exportResult?.exportBytes;
    bytes ??= state.previewResult?.previewBytes;
    if (bytes == null) {
      emit(state.copyWith(errorMessage: 'Render a result before sharing.'));
      return;
    }
    if (state.exportResult == null) {
      await renderHighQuality();
      bytes =
          state.exportResult?.exportBytes ?? state.previewResult?.previewBytes;
    }
    if (bytes == null) {
      return;
    }
    await _exportService.share(bytes,
        name: 'viral_style_${DateTime.now().millisecondsSinceEpoch}.jpg');
    if (!isClosed) {
      emit(state.copyWith(statusMessage: 'Share sheet opened.'));
    }
  }

  Future<List<dynamic>> batchApply(List<Uint8List> images) {
    final style = state.styleProfile;
    if (style == null) {
      return Future<List<dynamic>>.value(const <dynamic>[]);
    }
    return _batchApplyUseCase(
      targetImages: images,
      styleProfile: style,
      settings: state.settings,
      referenceBytes: state.referenceBytes,
    );
  }

  void clearMessages() {
    emit(state.copyWith(errorMessage: null, statusMessage: null));
  }

  void _updateSettings(statefulSettings) {
    emit(state.copyWith(
      settings: statefulSettings,
      exportResult: null,
      errorMessage: null,
    ));
    _schedulePreviewRefresh();
  }

  void _schedulePreviewRefresh({bool immediate = false}) {
    _previewDebounce?.cancel();
    if (!state.canStart) {
      return;
    }
    if (immediate) {
      unawaited(refreshPreview(force: true));
      return;
    }
    _previewDebounce = Timer(const Duration(milliseconds: 180), () {
      unawaited(refreshPreview());
    });
  }

  @override
  Future<void> close() {
    _previewDebounce?.cancel();
    return super.close();
  }
}
