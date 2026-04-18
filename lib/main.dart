import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'package:untitled2/shared/widgets/feature_card_widget.dart';

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/services/notification_service.dart';
import 'package:untitled2/core/services/task_persistence_service.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/features/ai_object_copy_paste/ai_object_copy_paste.dart';
import 'package:untitled2/features/smart_retouch/presentation/screens/smart_retouch_screen.dart';
import 'package:untitled2/features/ai_perspective_studio/presentation/screens/perspective_studio_screen.dart';
import 'package:untitled2/features/blur_photo/presentation/pages/blur_photo_page.dart';
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

import 'package:untitled2/vv/blemish_remover_screen.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/pages/remote_lama_flow_shell.dart';


import 'package:untitled2/core/background/bg_work_dispatcher.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/background/presentation/pages/operations_page.dart';
import 'package:untitled2/core/background/presentation/widgets/operations_badge_button.dart';
import 'package:untitled2/core/background/presentation/widgets/operations_drawer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final localeController = LocaleController(
    prefs,
    deviceLocale: ui.PlatformDispatcher.instance.locale,
  );

  Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // change to false for production
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0C0E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(
    EditorApp(
      config: AppConfig.fromEnvironment(),
      localeController: localeController,
    ),
  );
}

// أ¢â€‌â‚¬أ¢â€‌â‚¬ Root App أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬

class EditorApp extends StatelessWidget {
  const EditorApp({
    super.key,
    required this.config,
    required this.localeController,
  });

  final AppConfig config;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BgJobRepository>(create: (_) => BgJobRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<JobQueueCubit>(
            create: (context) => JobQueueCubit(context.read<BgJobRepository>()),
          ),
        ],
        child: AnimatedBuilder(
          animation: localeController,
          builder: (context, _) => MaterialApp(
            locale: localeController.locale,
            onGenerateTitle: (context) => context.tr.appTitle,
            debugShowCheckedModeBanner: false,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppL10nDelegate(),
              ...AppLocalizations.localizationsDelegates,
            ],
            theme: ThemeData.dark().copyWith(
              scaffoldBackgroundColor: const Color(0xFF0C0C0E),
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF56E39F),
                surface: Color(0xFF131417),
              ),
            ),
            home: HomeScreen(
              config: config,
              localeController: localeController,
            ),
          ),
        ),
      ),
    );
  }
}

// أ¢â€‌â‚¬أ¢â€‌â‚¬ Home Screen أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
    required this.localeController,
  });

  final AppConfig config;
  final LocaleController localeController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ImagePicker _picker = ImagePicker();
  bool _loading = false;
  late AnimationController _heroAnim;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  // أ¢â€‌â‚¬أ¢â€‌â‚¬ Image loading أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬

  Future<void> _pickAndNavigateUi(Widget Function(ui.Image) builder) async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null) return;
    setState(() => _loading = true);
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(
      context,
      _slide(builder(frame.image)),
    );
  }

  Future<void> _pickAndNavigateBytes(Widget Function(Uint8List) builder) async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _loading = true);
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.push(context, _slide(builder(bytes)));
  }

  Route<T> _slide<T>(Widget page) => PageRouteBuilder<T>(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

  void _openOperationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperationsPage()),
    );
  }

  // أ¢â€‌â‚¬أ¢â€‌â‚¬ Build أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬أ¢â€‌â‚¬

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: const OperationsDrawer(),
      backgroundColor: const Color(0xFF0C0C0E),
      body: Stack(children: [
        // Background glow
        Positioned(
          top: -120,
          left: -80,
          child: Container(
            width: 340,
            height: 340,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF56E39F).withValues(alpha: 0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF3D5AFE).withValues(alpha: 0.10),
                Colors.transparent,
              ]),
            ),
          ),
        ),

        SafeArea(
          child: FadeTransition(
            opacity: _fadeIn,
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF56E39F)))
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _HeroHeader(
                          onOpenOperationsDrawer: () =>
                              _scaffoldKey.currentState?.openEndDrawer(),
                          onOpenOperationsPage: _openOperationsPage,
                          localeController: widget.localeController,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 120), // Extra padding for the panel
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(_buildCards()),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ]),
    );
  }

  List<Widget> _buildCards() {
    final tr = context.tr;
    return [
      const SizedBox(height: 16),
      BlocBuilder<JobQueueCubit, JobQueueState>(
        builder: (context, queueState) => FeatureCardWidget(
          title: tr.operationsCenterTitle,
          subtitle: queueState.activeJobs.isEmpty
              ? tr.operationsCenterSubtitleEmpty
              : tr.operationsCenterSubtitleCount(queueState.activeJobs.length),
          icon: Icons.dashboard_customize_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF56E39F), Color(0xFF0B7A43)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF56E39F),
          onTap: _openOperationsPage,
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.smartRetouchTitle,
        subtitle: tr.smartRetouchSubtitle,
        icon: Icons.auto_fix_high_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF1E88E5),
        onTap: () => _pickAndNavigateUi(
          (image) => SmartRetouchScreen(
            initialImage: image,
            onApply: (bytes) {
              debugPrint('[Retouch] Applied \u2014 ${bytes.length} bytes');
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.magicEraserTitle,
        subtitle: tr.magicEraserSubtitle,
        icon: Icons.auto_fix_high_outlined,
        gradient: const LinearGradient(
          colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFFFFB300),
        onTap: () => Navigator.push(
          context,
          _slide(InpaintingFlowShell(config: widget.config)),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiObjectCopyPasteTitle,
        subtitle: tr.aiObjectCopyPasteSubtitle,
        icon: Icons.content_paste_go_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFFAB47BC),
        onTap: () => Navigator.push(
          context,
          _slide(const AiObjectCopyPastePage()),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.blemishRemoverTitle,
        subtitle: tr.blemishRemoverSubtitle,
        icon: Icons.face_retouching_natural_rounded,
        gradient: LinearGradient(
          colors: [
            const Color(0xFFE91E8C).withValues(alpha: 0.85),
            const Color(0xFF880E5F),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFFE91E8C),
        onTap: () => _pickAndNavigateUi(
          (image) => BlemishRemoverScreen(
            sourceImage: image,
            onApply: (bytes) {
              debugPrint('[Blemish] Applied \u2014 ${bytes.length} bytes');
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiPerspectiveStudioTitle,
        subtitle: tr.aiPerspectiveStudioSubtitle,
        icon: Icons.filter_center_focus_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF00B0FF),
        onTap: () => _pickAndNavigateUi(
          (image) => PerspectiveStudioScreen(
            initialImage: image,
            onApply: (bytes) {
              debugPrint('[Perspective] Applied \u2014 ${bytes.length} bytes');
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            onClose: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.blurPhotoTitle,
        subtitle: tr.blurPhotoSubtitle,
        icon: Icons.blur_circular_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFCC2936)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFFFF6B6B),
        onTap: () => _pickAndNavigateUi(
          (image) => BlurPhotoPage(
            initialImage: image,
            onApply: (bytes) {
              debugPrint('[BlurPhoto] Applied \u2014 ${bytes.length} bytes');
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            onClose: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiHealRegionTitle,
        subtitle: tr.aiHealRegionSubtitle,
        icon: Icons.healing,
        gradient: const LinearGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF0097A7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF00E5FF),
        onTap: () => _pickAndNavigateBytes(
          (bytes) => RemoteLamaFlowShell(
            initialImage: bytes,
            initialRoute: '/lama/heal',
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiCleanEdgesTitle,
        subtitle: tr.aiCleanEdgesSubtitle,
        icon: Icons.blur_on,
        gradient: const LinearGradient(
          colors: [Color(0xFF18FFFF), Color(0xFF00B8D4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        accentColor: const Color(0xFF18FFFF),
        onTap: () => _pickAndNavigateBytes(
          (bytes) => RemoteLamaFlowShell(
            initialImage: bytes,
            initialRoute: '/lama/clean',
          ),
        ),
      ),
    ];
  }
  // end of _buildCards
} // closes _HomeScreenState

// â”€â”€ Hero header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.onOpenOperationsDrawer,
    required this.onOpenOperationsPage,
    required this.localeController,
  });

  final VoidCallback onOpenOperationsDrawer;
  final VoidCallback onOpenOperationsPage;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // â”€â”€ Top bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Row(
          children: [
            // Logo chip
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                gradient: const LinearGradient(
                  colors: [Color(0xFF56E39F), Color(0xFF3D5AFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF56E39F).withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  const Icon(Icons.auto_awesome, color: Colors.black, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.appTitle,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  tr.appSubtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            OperationsBadgeButton(
              onTap: onOpenOperationsDrawer,
            ),
            const SizedBox(width: 8),
            PopupMenuButton<Locale>(
              tooltip: tr.languageMenuTooltip,
              initialValue: localeController.locale,
              color: const Color(0xFF131417),
              onSelected: (locale) {
                localeController.setLocale(locale);
              },
              itemBuilder: (context) => [
                PopupMenuItem<Locale>(
                  value: const Locale('en'),
                  child: Text(tr.languageEnglish),
                ),
                PopupMenuItem<Locale>(
                  value: const Locale('ar'),
                  child: Text(tr.languageArabic),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.language_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Version badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.10),
                  width: 1,
                ),
              ),
              child: Text(
                tr.proBadge,
                style: TextStyle(
                  color: const Color(0xFF56E39F).withValues(alpha: 0.9),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // â”€â”€ Heading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Text(
          tr.chooseA,
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.1,
            letterSpacing: -0.8,
          ),
        ),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF56E39F), Color(0xFF3D8BFD)],
          ).createShader(bounds),
          child: Text(
            tr.workspace,
            style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -0.8,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Text(
          tr.homeOpenToolHint,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        // â”€â”€ Stat pills â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Row(
          children: [
            _StatPill(label: '13', sub: tr.statTools),
            const SizedBox(width: 10),
            _StatPill(label: 'AI', sub: tr.statPowered),
            const SizedBox(width: 10),
            _StatPill(label: '4K', sub: tr.statQuality),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                onTap: onOpenOperationsPage,
                borderRadius: BorderRadius.circular(24),
                child: BlocBuilder<JobQueueCubit, JobQueueState>(
                  builder: (context, state) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.09),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Color(0xFF56E39F),
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          state.activeJobs.isEmpty
                              ? tr.operations
                              : tr.activeJobs(state.activeJobs.length),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ]),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.sub});
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.09),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            sub,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class InpaintingFlowShell extends StatefulWidget {
  const InpaintingFlowShell({
    super.key,
    required this.config,
  });

  final AppConfig config;

  @override
  State<InpaintingFlowShell> createState() => _InpaintingFlowShellState();
}

class _InpaintingFlowShellState extends State<InpaintingFlowShell> {
  late final InpaintingRepository _repository = InpaintingRepository(
    InpaintingApi(baseUrl: widget.config.baseUrl),
    apiKey: widget.config.apiKey,
  );

  late final GoRouter _router = GoRouter(
    initialLocation: AppRoutes.magicEraser,
    routes: [
      GoRoute(
        path: AppRoutes.magicEraser,
        builder: (context, state) => const HomePickPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePickPage(),
      ),
      GoRoute(
        path: AppRoutes.editor,
        builder: (context, state) => const EditorPage(),
      ),
      GoRoute(
        path: AppRoutes.processing,
        builder: (context, state) => const ProcessingPage(),
      ),
      GoRoute(
        path: AppRoutes.result,
        builder: (context, state) => const ResultPage(),
      ),
    ],
  );

  @override
  void initState() {
    super.initState();
    _initializeInpaintingServices();
  }

  Future<void> _initializeInpaintingServices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      TaskPersistenceService().init(prefs);
    } catch (_) {
      // Persistence is optional for this shell; continue without it.
    }

    try {
      await NotificationService().initialize();
    } catch (_) {
      // Notifications are optional; avoid breaking app startup.
    }
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
          BlocProvider(create: (_) => ImagePickCubit()),
          BlocProvider(create: (_) => DrawingCubit()),
          BlocProvider(create: (_) => ResultCubit()),
          BlocProvider(
            create: (_) => InpaintingBloc(repo: _repository),
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
} // InpaintingFlowShell

// â”€â”€ _FeatureCard removed â€“ replaced by FeatureCardWidget (shared/widgets/feature_card_widget.dart) â”€â”€

