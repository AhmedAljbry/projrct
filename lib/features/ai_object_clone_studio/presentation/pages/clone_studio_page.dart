import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/clone_usecases.dart';
import '../../utils/feature_dependencies.dart';
import '../bloc/clone_studio_bloc.dart';
import '../bloc/clone_studio_state.dart';
import '../widgets/clone_canvas.dart';
import '../widgets/clone_control_panel.dart';
import '../widgets/clone_toolbar.dart';

class CloneStudioPage extends StatelessWidget {
  final Uint8List initialImage;

  const CloneStudioPage({super.key, required this.initialImage});

  @override
  Widget build(BuildContext context) {
    return CloneFeatureDependencies(
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF0C0C0C),
            body: BlocProvider(
              create: (context) => CloneStudioBloc(
                extractObjectUseCase: context.read<ExtractObjectUseCase>(),
                harmonizeLayerUseCase: context.read<HarmonizeLayerUseCase>(),
                finalizeCloneImageUseCase:
                    context.read<FinalizeCloneImageUseCase>(),
              )..add(LoadImageEvent(initialImage)),
              child: const CloneStudioView(),
            ),
          );
        },
      ),
    );
  }
}

class CloneStudioView extends StatelessWidget {
  const CloneStudioView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CloneStudioBloc, CloneStudioState>(
      builder: (context, state) {
        return Stack(
          children: [
            const Positioned.fill(child: CloneCanvas()),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopBar(context, state),
            ),
            Positioned(
              top: 116,
              left: 16,
              right: 16,
              child: _buildGuideCard(state),
            ),
            if (state.mode == CloneStudioMode.place &&
                state.activeLayerId != null)
              const Positioned(
                left: 16,
                right: 16,
                bottom: 124,
                child: _ReadyToMoveCard(),
              ),
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
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty)
              Positioned(
                left: 16,
                right: 16,
                bottom: 220,
                child: _ErrorCard(message: state.errorMessage!),
              ),
            if (state.isLoading)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: _LoadingCard(),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, CloneStudioState state) {
    final title = state.mode == CloneStudioMode.select
        ? 'حدد الجسم بلمسة أو بخط سريع'
        : 'الجسم جاهز. اسحبه إلى المكان الجديد';

    return Container(
      height: 100,
      color: Colors.black.withValues(alpha: 0.82),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(width: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard(CloneStudioState state) {
    final message = state.mode == CloneStudioMode.select
        ? 'اضغط على الجسم مرة واحدة للتحديد الذكي، أو ارسم فوقه بشكل تقريبي.'
        : 'ظهر مربع أخضر حول العنصر. هذا يعني أن القص تم بنجاح وأن الجسم جاهز للتحريك.';

    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.74),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF56E39F).withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              state.mode == CloneStudioMode.select
                  ? Icons.auto_fix_high_rounded
                  : Icons.check_circle_rounded,
              color: const Color(0xFF56E39F),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF56E39F).withValues(alpha: 0.16),
        ),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: Color(0xFF56E39F),
            ),
          ),
          SizedBox(height: 12),
          Text(
            'جارِ تحديد الجسم',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadyToMoveCard extends StatelessWidget {
  const _ReadyToMoveCard();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF102017).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF56E39F).withValues(alpha: 0.42),
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(
              Icons.check_circle_rounded,
              color: Color(0xFF56E39F),
              size: 24,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'تم القص بنجاح. الجسم جاهز للتحريك الآن.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A1111),
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.35)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
