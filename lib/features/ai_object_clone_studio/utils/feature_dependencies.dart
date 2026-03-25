import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/features/ai_object_clone_studio/domain/repositories/iclone_repository.dart';
import '../domain/usecases/clone_usecases.dart';
import '../data/repositories/clone_repository.dart';
import '../engine/segmentation/segmentation_engine.dart';
import '../engine/blending/blending_engine.dart';

class CloneFeatureDependencies extends StatelessWidget {
  final Widget child;

  const CloneFeatureDependencies({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SegmentationEngine>(create: (_) => SegmentationEngine()),
        RepositoryProvider<BlendingEngine>(create: (_) => BlendingEngine()),
        RepositoryProvider<ICloneRepository>(
          create: (context) => CloneRepository(
            segmentationEngine: context.read<SegmentationEngine>(),
            blendingEngine: context.read<BlendingEngine>(),
          ),
        ),
        RepositoryProvider<ExtractObjectUseCase>(
          create: (context) => ExtractObjectUseCase(context.read<ICloneRepository>()),
        ),
        RepositoryProvider<HarmonizeLayerUseCase>(
          create: (context) => HarmonizeLayerUseCase(context.read<ICloneRepository>()),
        ),
        RepositoryProvider<FinalizeCloneImageUseCase>(
          create: (context) => FinalizeCloneImageUseCase(context.read<ICloneRepository>()),
        ),
      ],
      child: child,
    );
  }
}
