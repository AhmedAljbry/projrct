import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/monetization/services/monetization_engine.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/services/notification_service.dart';
import 'package:untitled2/core/services/task_persistence_service.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/inpainting/application/drawing/drawing_cubit.dart';
import 'package:untitled2/inpainting/application/image_pick_cubit.dart';
import 'package:untitled2/inpainting/application/inpainting_bloc/inpainting_bloc.dart';
import 'package:untitled2/inpainting/application/result_cubit.dart';
import 'package:untitled2/inpainting/data/inpainting_api.dart';
import 'package:untitled2/inpainting/data/inpainting_repository.dart';
import 'package:untitled2/inpainting/presentation/pages/editor/editor_page.dart';
import 'package:untitled2/inpainting/presentation/pages/home_pick_page.dart';
import 'package:untitled2/inpainting/presentation/pages/processing_page.dart';
import 'package:untitled2/inpainting/presentation/pages/result_page.dart';

class InpaintingFlowShell extends StatefulWidget {
  const InpaintingFlowShell({super.key, required this.config});

  final AppConfig config;

  @override
  State<InpaintingFlowShell> createState() => _InpaintingFlowShellState();
}

class _InpaintingFlowShellState extends State<InpaintingFlowShell> {
  late final InpaintingRepository _repository = InpaintingRepository(
    InpaintingApi(
      baseUrl: widget.config.baseUrl,
      ownerId: widget.config.ownerId,
    ),
    apiKey: widget.config.apiKey,
  );

  late final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.magicEraser,
    routes: [
      GoRoute(
          path: AppRoutes.magicEraser,
          builder: (_, __) => const HomePickPage()),
      GoRoute(path: AppRoutes.home, builder: (_, __) => const HomePickPage()),
      GoRoute(path: AppRoutes.editor, builder: (_, __) => const EditorPage()),
      GoRoute(
          path: AppRoutes.processing,
          builder: (_, __) => const ProcessingPage()),
      GoRoute(path: AppRoutes.result, builder: (_, __) => const ResultPage()),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      TaskPersistenceService().init(prefs);
    } catch (_) {}
    try {
      await NotificationService().initialize();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return MultiRepositoryProvider(
      providers: [RepositoryProvider<AppL10n>(create: (_) => AppL10n(locale))],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => ImagePickCubit()),
          BlocProvider(create: (_) => DrawingCubit()),
          BlocProvider(
            create: (_) => ResultCubit(
              monetizationEngine: getIt<MonetizationEngine>(),
            ),
          ),
          BlocProvider(
            create: (_) => InpaintingBloc(
              repo: _repository,
              monetizationEngine: getIt<MonetizationEngine>(),
            ),
          ),
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
      ),
    );
  }
}
