import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

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
import 'package:untitled2/core/ui/AppL10n.dart';

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
      ownerId: config.ownerId ?? 'app-user',
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
            final healCubit = HealRegionCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              healCubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
              value: healCubit,
              child: _ImageRequiredRoute(
                initialImage: widget.initialImage,
                onImageSelected: healCubit.setImage,
                child: const HealRegionPage(),
              ),
            );
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
            final cleanCubit = CleanEdgesCubit(
              submitJobUseCase: context.read<SubmitJobUseCase>(),
              pollJobStatusUseCase: context.read<PollJobStatusUseCase>(),
              getJobResultUseCase: context.read<GetJobResultUseCase>(),
            );
            if (widget.initialImage != null) {
              cleanCubit.setImage(widget.initialImage!);
            }
            return BlocProvider.value(
              value: cleanCubit,
              child: _ImageRequiredRoute(
                initialImage: widget.initialImage,
                onImageSelected: cleanCubit.setImage,
                child: const CleanEdgesPage(),
              ),
            );
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
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppL10n>(
          create: (_) => AppL10n(locale),
        ),
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
        locale: locale,
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppL10nDelegate(),
          ...AppLocalizations.localizationsDelegates,
        ],
        theme: Theme.of(context),
        routerConfig: _router,
      ),
    );
  }
}

class _ImageRequiredRoute extends StatefulWidget {
  const _ImageRequiredRoute({
    required this.initialImage,
    required this.onImageSelected,
    required this.child,
  });

  final Uint8List? initialImage;
  final ValueChanged<Uint8List> onImageSelected;
  final Widget child;

  @override
  State<_ImageRequiredRoute> createState() => _ImageRequiredRouteState();
}

class _ImageRequiredRouteState extends State<_ImageRequiredRoute> {
  bool _isPicking = false;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    final initialImage = widget.initialImage;
    if (initialImage != null) {
      widget.onImageSelected(initialImage);
      _isReady = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _pickImage();
      });
    }
  }

  Future<void> _pickImage() async {
    if (_isPicking || !mounted) {
      return;
    }
    _isPicking = true;
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (!mounted) {
      return;
    }
    if (file == null) {
      context.go('/editor');
      return;
    }
    final bytes = await file.readAsBytes();
    if (!mounted) {
      return;
    }
    widget.onImageSelected(bytes);
    setState(() {
      _isReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isReady) {
      return widget.child;
    }

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
