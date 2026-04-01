import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/features/remote_lama_tools/data/datasources/lama_remote_data_source.dart';
import 'package:untitled2/features/remote_lama_tools/data/repositories/lama_repository_impl.dart';
import 'package:untitled2/features/remote_lama_tools/domain/repositories/lama_repository.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/background/background_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/background/background_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/clean_edges/clean_edges_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/clean_edges/clean_edges_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/descratch/descratch_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/descratch/descratch_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/expand_canvas/expand_canvas_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/expand_canvas/expand_canvas_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/heal_region/heal_region_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/hub/remote_lama_hub_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/hub/remote_lama_hub_page.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_manual_mask_cubit.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/repair_damage/repair_damage_page.dart';
import 'package:untitled2/features/retouch_mask_assist/data/repositories/retouch_mask_assist_repository_impl.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/repositories/retouch_mask_assist_repository.dart';
import 'package:untitled2/features/retouch_mask_assist/domain/usecases/retouch_mask_assist_usecases.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/expand/expand_mask_assist_cubit.dart';
import 'package:untitled2/features/retouch_mask_assist/presentation/bloc/repair_mask_assist_cubit.dart';

class RemoteLamaFlowShell extends StatefulWidget {
  final Uint8List? initialImage;
  final String initialRoute;
  final AppConfig? config;

  const RemoteLamaFlowShell({
    super.key,
    this.initialImage,
    this.initialRoute = '/editor',
    this.config,
  });

  @override
  State<RemoteLamaFlowShell> createState() => _RemoteLamaFlowShellState();
}

class _RemoteLamaFlowShellState extends State<RemoteLamaFlowShell> {
  late final LamaRemoteDataSource _dataSource;
  late final LamaRepository _repository;
  late final RetouchMaskAssistRepository _retouchMaskAssistRepository;
  late final GoRouter _router;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    final config = widget.config ?? AppConfig.fromEnvironment();
    _client = http.Client();
    _dataSource = LamaRemoteDataSourceImpl(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey ?? '',
      client: _client,
    );
    _repository = LamaRepositoryImpl(remoteDataSource: _dataSource);
    _retouchMaskAssistRepository = RetouchMaskAssistRepositoryImpl();

    _router = GoRouter(
      initialLocation: widget.initialRoute,
      routes: [
        GoRoute(
          path: '/editor',
          builder: (context, state) => BlocProvider(
            create: (_) => RemoteLamaHubCubit(remoteDataSource: _dataSource),
            child: const RemoteLamaHubPage(),
          ),
        ),
        GoRoute(
          path: '/lama/heal',
          builder: (context, state) {
            final cubit = HealRegionCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              cubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
                value: cubit, child: const HealRegionPage());
          },
        ),
        GoRoute(
          path: '/lama/repair',
          builder: (context, state) {
            final repairCubit = RepairDamageCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            final manualMaskCubit = RepairDamageManualMaskCubit(
              buildMaskPreviewUseCase: context.read<BuildMaskPreviewUseCase>(),
              applyMaskBrushStrokeUseCase:
                  context.read<ApplyMaskBrushStrokeUseCase>(),
              transformMaskUseCase: context.read<TransformMaskUseCase>(),
              exportProcessingMaskUseCase:
                  context.read<ExportProcessingMaskUseCase>(),
            );
            final maskAssistCubit = RepairMaskAssistCubit(
              generateMaskSuggestionUseCase:
                  context.read<GenerateMaskSuggestionUseCase>(),
              buildMaskPreviewUseCase: context.read<BuildMaskPreviewUseCase>(),
              applyMaskBrushStrokeUseCase:
                  context.read<ApplyMaskBrushStrokeUseCase>(),
              transformMaskUseCase: context.read<TransformMaskUseCase>(),
              exportProcessingMaskUseCase:
                  context.read<ExportProcessingMaskUseCase>(),
            );
            if (widget.initialImage != null) {
              repairCubit.setImage(widget.initialImage!);
              manualMaskCubit.setImage(widget.initialImage!);
              maskAssistCubit.setImage(widget.initialImage!);
            }
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: repairCubit),
                BlocProvider.value(value: manualMaskCubit),
                BlocProvider.value(value: maskAssistCubit),
              ],
              child: const RepairDamagePage(),
            );
          },
        ),
        GoRoute(
          path: '/lama/descratch',
          builder: (context, state) {
            final cubit = DescratchCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              cubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
                value: cubit, child: const DescratchPage());
          },
        ),
        GoRoute(
          path: '/lama/background',
          builder: (context, state) {
            final cubit = BackgroundCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              cubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
                value: cubit, child: const BackgroundPage());
          },
        ),
        GoRoute(
          path: '/lama/expand',
          builder: (context, state) {
            final cubit = ExpandCanvasCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            final assistCubit = ExpandMaskAssistCubit(
              generateMaskSuggestionUseCase:
                  context.read<GenerateMaskSuggestionUseCase>(),
              buildMaskPreviewUseCase: context.read<BuildMaskPreviewUseCase>(),
              applyMaskBrushStrokeUseCase:
                  context.read<ApplyMaskBrushStrokeUseCase>(),
              transformMaskUseCase: context.read<TransformMaskUseCase>(),
              exportProcessingMaskUseCase:
                  context.read<ExportProcessingMaskUseCase>(),
            );
            if (widget.initialImage != null) {
              cubit.setImage(widget.initialImage!);
              assistCubit.setImage(widget.initialImage!);
            }
            return MultiBlocProvider(
              providers: [
                BlocProvider.value(value: cubit),
                BlocProvider.value(value: assistCubit),
              ],
              child: const ExpandCanvasPage(),
            );
          },
        ),
        GoRoute(
          path: '/lama/clean',
          builder: (context, state) {
            final cubit = CleanEdgesCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              cubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
                value: cubit, child: const CleanEdgesPage());
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _client.close();
    _retouchMaskAssistRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<LamaRepository>.value(value: _repository),
        RepositoryProvider<RetouchMaskAssistRepository>.value(
            value: _retouchMaskAssistRepository),
        RepositoryProvider(create: (_) => SubmitJobUseCase(_repository)),
        RepositoryProvider(create: (_) => PollJobStatusUseCase(_repository)),
        RepositoryProvider(create: (_) => GetJobResultUseCase(_repository)),
        RepositoryProvider(
            create: (_) =>
                GenerateMaskSuggestionUseCase(_retouchMaskAssistRepository)),
        RepositoryProvider(
            create: (_) =>
                BuildMaskPreviewUseCase(_retouchMaskAssistRepository)),
        RepositoryProvider(
            create: (_) =>
                ApplyMaskBrushStrokeUseCase(_retouchMaskAssistRepository)),
        RepositoryProvider(
            create: (_) => TransformMaskUseCase(_retouchMaskAssistRepository)),
        RepositoryProvider(
            create: (_) =>
                ExportProcessingMaskUseCase(_retouchMaskAssistRepository)),
      ],
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        theme: Theme.of(context),
        routerConfig: _router,
      ),
    );
  }
}
