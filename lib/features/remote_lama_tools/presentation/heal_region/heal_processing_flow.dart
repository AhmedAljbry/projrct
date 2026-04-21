// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/monetization/services/monetization_engine.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_result_page.dart';
import 'package:untitled2/inpainting/application/image_pick_cubit.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_bloc.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_event.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_state.dart';
import 'package:untitled2/inpainting/data/inpainting_api.dart';
import 'package:untitled2/inpainting/data/inpainting_repository.dart';
import 'package:untitled2/inpainting/domain/inpainting_failure.dart';
import 'package:untitled2/inpainting/domain/inpainting_status.dart';
import 'package:untitled2/inpainting/presentation/pages/processing_page.dart';

class HealProcessingFlow extends StatefulWidget {
  const HealProcessingFlow({
    super.key,
    required this.originalBytes,
    required this.healCubit,
  });

  final Uint8List originalBytes;
  final HealRegionCubit healCubit;

  @override
  State<HealProcessingFlow> createState() => _HealProcessingFlowState();
}

class _HealProcessingFlowState extends State<HealProcessingFlow> {
  late final _HealBridgeImagePickCubit _imagePickCubit;
  late final _HealBridgeInpaintingBloc _inpaintingBloc;
  late final StreamSubscription<HealRegionState> _healSubscription;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _imagePickCubit = _HealBridgeImagePickCubit();
    _imagePickCubit.setBytes(widget.originalBytes);

    _inpaintingBloc = _HealBridgeInpaintingBloc(healCubit: widget.healCubit);
    _inpaintingBloc.syncFromHealState(widget.healCubit.state);
    _healSubscription = widget.healCubit.stream.listen(
      _inpaintingBloc.syncFromHealState,
    );

    _router = GoRouter(
      initialLocation: AppRoutes.processing,
      routes: [
        GoRoute(
          path: AppRoutes.processing,
          builder: (context, state) => const ProcessingPage(),
        ),
        GoRoute(
          path: AppRoutes.result,
          builder: (context, state) {
            final resultBytes = context.watch<InpaintingBloc>().state.result;
            return RemoteLamaResultPage(
              title: 'Heal Result',
              resultBytes: resultBytes ?? widget.originalBytes,
              originalBytes: widget.originalBytes,
              onReset: () => _closeFlow(),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.editor,
          builder: (context, state) => _HealFlowExitPage(onExit: _closeFlow),
        ),
      ],
    );
  }

  void _closeFlow() {
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _healSubscription.cancel();
    _router.dispose();
    _imagePickCubit.close();
    _inpaintingBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppL10n>(
          create: (_) => AppL10n(locale),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ImagePickCubit>.value(value: _imagePickCubit),
          BlocProvider<InpaintingBloc>.value(value: _inpaintingBloc),
        ],
        child: MaterialApp.router(
          locale: locale,
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          routerConfig: _router,
        ),
      ),
    );
  }
}

class _HealFlowExitPage extends StatefulWidget {
  const _HealFlowExitPage({required this.onExit});

  final VoidCallback onExit;

  @override
  State<_HealFlowExitPage> createState() => _HealFlowExitPageState();
}

class _HealFlowExitPageState extends State<_HealFlowExitPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onExit();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}

class _HealBridgeImagePickCubit extends ImagePickCubit {
  Future<void> setBytes(Uint8List bytes) async {
    emit(ImagePickLoading());
    final image = await _decode(bytes);
    emit(ImagePickReady(bytes: bytes, uiImage: image));
  }

  Future<ui.Image> _decode(Uint8List bytes) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromList(bytes, completer.complete);
    return completer.future;
  }
}

class _HealBridgeInpaintingBloc extends InpaintingBloc {
  _HealBridgeInpaintingBloc({required this.healCubit})
      : super(
          repo: InpaintingRepository(
            InpaintingApi(baseUrl: 'https://localhost.invalid'),
          ),
          monetizationEngine: getIt<MonetizationEngine>(),
        );

  final HealRegionCubit healCubit;

  @override
  void add(InpaintingEvent event) {
    if (event is InpaintingCancel) {
      emit(
        state.copyWith(
          status: InpaintingStatus.cancelled,
          failure: const InpaintingFailure(
            code: 'cancelled',
            messageKey: 'cancelled',
          ),
          serverStage: 'cancelled',
          serverMessage: null,
          serverProgress: null,
          lastUpdatedAt: DateTime.now(),
        ),
      );
      return;
    }
    if (event is InpaintingReset) {
      emit(InpaintingState.idle());
      return;
    }
    super.add(event);
  }

  @override
  Future<void> retryLastSubmission() async {}

  void syncFromHealState(HealRegionState healState) {
    final now = DateTime.now();
    final startedAt = state.startedAt ?? now;

    switch (healState) {
      case HealRegionInitial():
        emit(InpaintingState.idle());
      case HealRegionReady():
        if (state.status == InpaintingStatus.idle) {
          emit(
            InpaintingState(
              status: InpaintingStatus.preparing,
              startedAt: startedAt,
              lastUpdatedAt: now,
              serverStage: 'preparing',
              serverMessage: 'Preparing heal job',
            ),
          );
        }
      case HealRegionSubmitting():
        emit(
          InpaintingState(
            status: InpaintingStatus.preparing,
            startedAt: startedAt,
            lastUpdatedAt: now,
            serverStage: 'preparing',
            serverMessage: 'Preparing heal job',
          ),
        );
      case HealRegionProcessing(:final status):
        emit(
          state.copyWith(
            status: status.status == 'queued'
                ? InpaintingStatus.queued
                : status.isCompleted
                    ? InpaintingStatus.downloading
                    : InpaintingStatus.processing,
            jobId: status.jobId,
            serverProgress: status.progress,
            serverStage: status.status,
            serverMessage: status.message,
            startedAt: startedAt,
            lastUpdatedAt: now,
            clearFailure: true,
          ),
        );
      case HealRegionSuccess(:final resultBytes):
        emit(
          state.copyWith(
            status: InpaintingStatus.success,
            result: resultBytes,
            serverProgress: 100,
            serverStage: 'result_ready',
            serverMessage: 'Result downloaded successfully',
            startedAt: startedAt,
            lastUpdatedAt: now,
            clearFailure: true,
          ),
        );
      case HealRegionFailure(:final message):
        emit(
          state.copyWith(
            status: InpaintingStatus.failed,
            failure: const InpaintingFailure(
              code: 'background_failed',
              messageKey: 'failed',
            ),
            serverStage: 'failed',
            serverProgress: null,
            serverMessage: message,
            startedAt: startedAt,
            lastUpdatedAt: now,
          ),
        );
    }
  }
}
