import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';
import '../widgets/clone_canvas.dart';
import '../widgets/clone_toolbar.dart';
import '../widgets/clone_control_panel.dart';
import '../../utils/feature_dependencies.dart';
import '../../domain/usecases/clone_usecases.dart';

class CloneStudioPage extends StatelessWidget {
  final Uint8List initialImage;

  const CloneStudioPage({super.key, required this.initialImage});

  @override
  Widget build(BuildContext context) {
    return CloneFeatureDependencies(
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: Colors.red, // Diagnostic color
            body: BlocProvider(
              create: (context) => CloneStudioBloc(
                extractObjectUseCase: context.read<ExtractObjectUseCase>(),
                harmonizeLayerUseCase: context.read<HarmonizeLayerUseCase>(),
                finalizeCloneImageUseCase: context.read<FinalizeCloneImageUseCase>(),
              )..add(LoadImageEvent(initialImage)),
              child: const CloneStudioView(),
            ),
          );
        }
      ),
    );
  }
}
// Fix: CloneStudioPage needs to provide the Bloc within the dependencies scope.

class CloneStudioView extends StatelessWidget {
  const CloneStudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main Canvas
        const Positioned.fill(
          child: CloneCanvas(),
        ),

        // Top Bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopBar(context),
        ),

        // Bottom Tools
        Positioned(
          bottom: 20,
          left: 20,
          right: 20,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CloneControlPanel(),
              const SizedBox(height: 16),
              const CloneToolbar(),
            ],
          ),
        ),

        // Loading Overlay
        BlocBuilder<CloneStudioBloc, CloneStudioState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Container(
                color: Colors.black54,
                child: const Center(child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 100,
      color: Colors.black.withValues(alpha: 0.8),
      child: Container(
          alignment: Alignment.bottomCenter,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Text(
                'AI CLONE STUDIO',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Trigger export
                },
                child: const Text('SAVE', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),

    );
  }
}
