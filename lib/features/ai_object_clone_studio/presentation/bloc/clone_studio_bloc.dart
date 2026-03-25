import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/ai_object_clone_studio/domain/repositories/iclone_repository.dart';
import '../../domain/usecases/clone_usecases.dart';
import 'clone_studio_state.dart';
import '../../domain/entities/clone_entities.dart';

class CloneStudioBloc extends Bloc<CloneStudioEvent, CloneStudioState> {
  final ExtractObjectUseCase extractObjectUseCase;
  final HarmonizeLayerUseCase harmonizeLayerUseCase;
  final FinalizeCloneImageUseCase finalizeCloneImageUseCase;

  CloneStudioBloc({
    required this.extractObjectUseCase,
    required this.harmonizeLayerUseCase,
    required this.finalizeCloneImageUseCase,
  }) : super(const CloneStudioState()) {
    on<LoadImageEvent>(_onLoadImage);
    on<SelectObjectEvent>(_onSelectObject);
    on<UpdateLayerTransformEvent>(_onUpdateLayerTransform);
    on<UpdateLayerHarmonizationEvent>(_onUpdateLayerHarmonization);
    on<DeleteLayerEvent>(_onDeleteLayer);
  }

  void _onLoadImage(LoadImageEvent event, Emitter<CloneStudioState> emit) {
    print('DEBUG: CloneStudioBloc - Loading image, size: ${event.image.length}');
    emit(state.copyWith(
      baseImage: event.image,
      mode: CloneStudioMode.select,
      isLoading: false,
    ));
  }

  Future<void> _onSelectObject(SelectObjectEvent event, Emitter<CloneStudioState> emit) async {
    if (state.baseImage == null) return;
    
    emit(state.copyWith(isLoading: true));
    try {
      final clonedObject = await extractObjectUseCase.call(
        imageBytes: state.baseImage!,
        points: event.points,
        mode: SelectionMode.smart,
      );

      final newLayer = EditLayer(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        object: clonedObject,
        transform: TransformState(),
        harmonization: HarmonizationSettings(),
      );

      emit(state.copyWith(
        layers: [...state.layers, newLayer],
        activeLayerId: newLayer.id,
        mode: CloneStudioMode.place,
        isLoading: false,
      ));
    } catch (e) {
       emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  void _onUpdateLayerTransform(UpdateLayerTransformEvent event, Emitter<CloneStudioState> emit) {
    final updatedLayers = state.layers.map((layer) {
      if (layer.id == event.id) {
        return layer.copyWith(transform: event.transform);
      }
      return layer;
    }).toList();
    emit(state.copyWith(layers: updatedLayers));
  }

  void _onUpdateLayerHarmonization(UpdateLayerHarmonizationEvent event, Emitter<CloneStudioState> emit) {
    final updatedLayers = state.layers.map((layer) {
      if (layer.id == event.id) {
        return layer.copyWith(harmonization: event.harmonization);
      }
      return layer;
    }).toList();
    emit(state.copyWith(layers: updatedLayers));
  }

  void _onDeleteLayer(DeleteLayerEvent event, Emitter<CloneStudioState> emit) {
    final updatedLayers = state.layers.where((layer) => layer.id != event.id).toList();
    emit(state.copyWith(
      layers: updatedLayers,
      activeLayerId: state.activeLayerId == event.id ? null : state.activeLayerId,
    ));
  }
}
