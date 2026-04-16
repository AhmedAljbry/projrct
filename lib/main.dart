import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled2/shared/widgets/feature_card_widget.dart';

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/services/notification_service.dart';
import 'package:untitled2/core/services/task_persistence_service.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/features/ai_object_clone_studio/presentation/pages/clone_studio_page.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF0C0C0E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(EditorApp(config: AppConfig.fromEnvironment()));
}

// â”€â”€ Root App â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class EditorApp extends StatelessWidget {
  const EditorApp({
    super.key,
    required this.config,
  });

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Photo Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0C0C0E),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF56E39F),
          surface: const Color(0xFF131417),
        ),
      ),
      home: HomeScreen(config: config),
    );
  }
}

// â”€â”€ Home Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.config,
  });

  final AppConfig config;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
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

  // â”€â”€ Image loading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

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

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      const SliverToBoxAdapter(child: _HeroHeader()),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
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

  List<Widget> _buildCards() => [
        // ── Coins Wallet ──────────────────────────────────────────────────────
        // ── Open studio without photo (subtextual action kept intact) ─────────

        const SizedBox(height: 16),

        // ── Smart Retouch ─────────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'Smart Retouch',
          subtitle: 'Clone heal · Blemish fix · Non-destructive',
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

        // ── Magic Eraser Inpainting ───────────────────────────────────────────
        FeatureCardWidget(
          title: 'Magic Eraser Inpainting',
          subtitle: 'Remove objects · Paint mask · AI fill',
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

        // ── Smart Clone Studio ────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'Smart Clone Studio (AI)',
          subtitle: 'Copy · Move · Remove objects with AI',
          icon: Icons.copy_all_rounded,
          gradient: const LinearGradient(
            colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF3D5AFE),
          onTap: () => _pickAndNavigateBytes(
            (bytes) => CloneStudioPage(initialImage: bytes),
          ),
        ),

        const SizedBox(height: 16),

        // ── AI Object Copy Paste ──────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Object Copy Paste',
          subtitle: 'Lift objects and paste anywhere',
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

        // ── Blemish Remover ───────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'Blemish Remover',
          subtitle: 'One-tap skin perfection',
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

        // ── AI Perspective Studio ─────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Perspective Studio',
          subtitle: 'Straighten · Rectify · Smart scan',
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
                debugPrint(
                    '[Perspective] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
              onClose: () {
                if (Navigator.of(context).canPop()) Navigator.of(context).pop();
              },
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Blur Photo ────────────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'Blur Photo',
          subtitle: 'Smart · Circle · Line – premium background blur',
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

        // ── AI Heal Region ────────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Heal Region',
          subtitle: 'Small targeted repair with radius control',
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

        // ── AI Repair Damage ──────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Repair Damage',
          subtitle: 'Restore missing or damaged areas using AI',
          icon: Icons.build_circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF00B0FF), Color(0xFF0081CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF00B0FF),
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/repair',
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── AI Expand Canvas ──────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Expand Canvas',
          subtitle: 'Outpaint and extend scene edges seamlessly',
          icon: Icons.crop_free,
          gradient: const LinearGradient(
            colors: [Color(0xFF40C4FF), Color(0xFF01579B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: const Color(0xFF40C4FF),
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/expand',
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── AI Clean Edges ────────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'AI Clean Edges',
          subtitle: 'Professional mask boundary cleanup',
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

        const SizedBox(height: 16),

        // ── More Remote Tools ─────────────────────────────────────────────────
        FeatureCardWidget(
          title: 'More Remote Tools',
          subtitle: 'Descratch · Background Cleanup · Studio Hub',
          icon: Icons.more_horiz_rounded,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.06),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          accentColor: Colors.white54,
          onTap: () => Navigator.push(
            context,
            _slide(const RemoteLamaFlowShell()),
          ),
        ),
      ];
  // ── end of _buildCards ──────────────────────────────────────────────────────
} // closes _HomeScreenState

// ── Hero header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Top bar ────────────────────────────────────────────────────────
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
                const Text(
                  'AI Photo Studio',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  'Professional editing tools',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
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
                'PRO',
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

        // ── Heading ────────────────────────────────────────────────────────
        const Text(
          'Choose a',
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
          child: const Text(
            'Workspace',
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
          'Tap any tool below to open it with a photo from your gallery.',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 13.5,
            height: 1.4,
          ),
        ),

        const SizedBox(height: 20),

        // ── Stat pills ─────────────────────────────────────────────────────
        Row(
          children: [
            _StatPill(label: '13', sub: 'Tools'),
            const SizedBox(width: 10),
            _StatPill(label: 'AI', sub: 'Powered'),
            const SizedBox(width: 10),
            _StatPill(label: '4K', sub: 'Quality'),
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
          debugShowCheckedModeBanner: false,
          theme: Theme.of(context),
          routerConfig: _router,
        ),
      ),
    );
  }
} // InpaintingFlowShell

// ── _FeatureCard removed – replaced by FeatureCardWidget (shared/widgets/feature_card_widget.dart) ──
