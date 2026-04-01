import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/routing/app_routes.dart';
import 'package:untitled2/core/services/notification_service.dart';
import 'package:untitled2/core/services/task_persistence_service.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/features/ai_blur_focus_standalone/presentation/screen/ai_blur_focus_screen.dart';
import 'package:untitled2/features/ai_object_clone_studio/presentation/pages/clone_studio_page.dart';
import 'package:untitled2/features/ai_object_copy_paste/ai_object_copy_paste.dart';
import 'package:untitled2/features/coins_wallet/presentation/pages/coins_wallet_host_page.dart';
import 'package:untitled2/features/smart_retouch/presentation/screens/smart_retouch_screen.dart';
import 'package:untitled2/features/style_transfer/presentation/screens/style_transfer_home_screen.dart';
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
import 'package:untitled2/unified_editor_workspace/unified_editor_routes.dart';
import 'package:untitled2/unified_editor_workspace/unified_editor_workspace.dart';
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
        // AI Blur Focus â€” primary featured card
        _FeatureCard(
          index: 0,
          icon: Icons.blur_on_rounded,
          title: 'AI Blur Focus Studio',
          subtitle: 'Smart subject آ· Circle آ· Line depth-of-field',
          gradient: const LinearGradient(
            colors: [Color(0xFF56E39F), Color(0xFF2BC87E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.black,
          featured: true,
          onTap: () => _pickAndNavigateUi(
            (image) => AiBlurFocusScreen(
              initialImage: image,
              onApply: (bytes) {
                debugPrint(
                    '[Blur Studio] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 10,
          icon: Icons.auto_awesome_motion_rounded,
          title: 'AI Style Transfer Studio',
          subtitle: 'Reference-based cinematic mapping with safe viral polish',
          gradient: const LinearGradient(
            colors: [Color(0xFFFF8A3D), Color(0xFFFF5E62)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.black,
          onTap: () => Navigator.push(
            context,
            _slide(const StyleTransferHomeScreen()),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 11,
          icon: Icons.monetization_on_rounded,
          title: 'Coins Wallet',
          subtitle: 'Earn, buy, and spend coins at ${AppRoutes.coinsWallet}',
          gradient: const LinearGradient(
            colors: [Color(0xFFF4D58D), Color(0xFFC89B3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.black,
          onTap: () => Navigator.push(
            context,
            _slide(
              CoinsWalletHostPage(
                config: widget.config,
                userId: CoinsWalletHostPage.demoCoinsUserId,
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Unified Creative Studio (Quick آ· Pro آ· Architect)
        _FeatureCard(
          index: 1,
          icon: Icons.dashboard_customize_rounded,
          title: 'Unified Creative Studio',
          subtitle: 'Quick آ· Pro آ· Architect â€” one adaptive workspace',
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF311B92)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => UnifiedEditorWorkspace(
              title: 'Unified Creative Studio',
              sourceImageBytes: bytes,
            ),
          ),
        ),

        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => openUnifiedEditorWorkspace(context),
              child: const Text(
                'Open unified studio without a photo',
                style: TextStyle(
                  color: Colors.white60,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Smart Retouch
        _FeatureCard(
          index: 2,
          icon: Icons.auto_fix_high_rounded,
          title: 'Smart Retouch',
          subtitle: 'Clone heal آ· Blemish fix آ· Non-destructive',
          gradient: const LinearGradient(
            colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateUi(
            (image) => SmartRetouchScreen(
              initialImage: image,
              onApply: (bytes) {
                debugPrint('[Retouch] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 3,
          icon: Icons.auto_fix_high_outlined,
          title: 'Magic Eraser Inpainting',
          subtitle: 'Remove objects ط¢آ· Paint mask ط¢آ· AI fill',
          gradient: const LinearGradient(
            colors: [Color(0xFFFFB300), Color(0xFFFF6F00)],
          ),
          foreground: Colors.black,
          onTap: () => Navigator.push(
            context,
            _slide(InpaintingFlowShell(config: widget.config)),
          ),
        ),

        const SizedBox(height: 14),

        // Smart Clone Studio
        _FeatureCard(
          index: 4,
          icon: Icons.copy_all_rounded,
          title: 'Smart Clone Studio (AI)',
          subtitle: 'Copy آ· Move آ· Remove objects with AI',
          gradient: const LinearGradient(
            colors: [Color(0xFF3D5AFE), Color(0xFF1A237E)],
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => CloneStudioPage(initialImage: bytes),
          ),
        ),

        const SizedBox(height: 14),

        // AI Object Copy Paste
        _FeatureCard(
          index: 5,
          icon: Icons.content_paste_go_rounded,
          title: 'AI Object Copy Paste',
          subtitle: 'Lift objects and paste anywhere',
          gradient: const LinearGradient(
            colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
          ),
          foreground: Colors.white,
          onTap: () => Navigator.push(
            context,
            _slide(const AiObjectCopyPastePage()),
          ),
        ),

        const SizedBox(height: 14),

        // Blemish Remover
        _FeatureCard(
          index: 6,
          icon: Icons.face_retouching_natural_rounded,
          title: 'Blemish Remover',
          subtitle: 'One-tap skin perfection',
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.10),
              Colors.white.withValues(alpha: 0.05),
            ],
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateUi(
            (image) => BlemishRemoverScreen(
              sourceImage: image,
              onApply: (bytes) {
                debugPrint('[Blemish] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        // AI Perspective Studio (NEW)
        _FeatureCard(
          index: 7,
          icon: Icons.filter_center_focus_rounded,
          title: 'AI Perspective Studio',
          subtitle: 'Straighten آ· Rectify آ· Smart scan',
          gradient: const LinearGradient(
            colors: [Color(0xFF00B0FF), Color(0xFF0091EA)],
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateUi(
            (image) => PerspectiveStudioScreen(
              initialImage: image,
              onApply: (bytes) {
                debugPrint(
                    '[Perspective] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Blur Photo
        _FeatureCard(
          index: 8,
          icon: Icons.blur_circular_rounded,
          title: 'Blur Photo',
          subtitle: 'Smart آ· Circle آ· Line â€” premium background blur',
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFCC2936)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateUi(
            (image) => BlurPhotoPage(
              initialImage: image,
              onApply: (bytes) {
                debugPrint('[BlurPhoto] Applied \u2014 ${bytes.length} bytes');
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 9,
          icon: Icons.healing,
          title: 'AI Heal Region',
          subtitle: 'Small targeted repair with radius control',
          gradient: const LinearGradient(
            colors: [Color(0xFF00E5FF), Color(0xFF0097A7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.black,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/heal',
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 10,
          icon: Icons.build_circle,
          title: 'AI Repair Damage',
          subtitle: 'Restore missing or damaged areas using AI',
          gradient: const LinearGradient(
            colors: [Color(0xFF00B0FF), Color(0xFF0081CB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/repair',
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 11,
          icon: Icons.crop_free,
          title: 'AI Expand Canvas',
          subtitle: 'Outpaint and extend scene edges seamlessly',
          gradient: const LinearGradient(
            colors: [Color(0xFF40C4FF), Color(0xFF01579B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.white,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/expand',
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 12,
          icon: Icons.blur_on,
          title: 'AI Clean Edges',
          subtitle: 'Professional mask boundary cleanup',
          gradient: const LinearGradient(
            colors: [Color(0xFF18FFFF), Color(0xFF00B8D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foreground: Colors.black,
          onTap: () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/clean',
            ),
          ),
        ),

        const SizedBox(height: 14),

        _FeatureCard(
          index: 13,
          icon: Icons.more_horiz_rounded,
          title: 'More Remote Tools',
          subtitle: 'Descratch · Background Cleanup · Studio Hub',
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.12),
              Colors.white.withValues(alpha: 0.06),
            ],
          ),
          foreground: Colors.white70,
          onTap: () => Navigator.push(
            context,
            _slide(const RemoteLamaFlowShell()),
          ),
        ),
      ];
}

// â”€â”€ Hero header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeroHeader extends StatelessWidget {
  const _HeroHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 32, 22, 28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF56E39F), Color(0xFF3D5AFE)],
              ),
            ),
            child:
                const Icon(Icons.auto_awesome, color: Colors.black, size: 24),
          ),
          const SizedBox(width: 12),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI Photo Studio',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20)),
            Text('Professional editing tools',
                style: TextStyle(color: Colors.white54, fontSize: 12.5)),
          ]),
        ]),
        const SizedBox(height: 26),
        const Text(
          'Choose a\nWorkspace',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any tool below to open it with a photo from your gallery.',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
        ),
      ]),
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
}

// â”€â”€ Feature card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _FeatureCard extends StatefulWidget {
  const _FeatureCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.foreground,
    required this.onTap,
    this.featured = false,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final Color foreground;
  final VoidCallback onTap;
  final bool featured;

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final h = widget.featured ? 128.0 : 96.0;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.965 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: h,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: _pressed
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.38),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            child: Row(children: [
              // Icon
              Container(
                width: widget.featured ? 56 : 48,
                height: widget.featured ? 56 : 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.20),
                  borderRadius:
                      BorderRadius.circular(widget.featured ? 18 : 15),
                ),
                child: Icon(widget.icon,
                    color: widget.foreground, size: widget.featured ? 28 : 24),
              ),
              const SizedBox(width: 16),
              // Text
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.featured)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'FEATURED',
                            style: TextStyle(
                                color:
                                    widget.foreground.withValues(alpha: 0.88),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1),
                          ),
                        ),
                      Text(widget.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: widget.foreground,
                              fontWeight: FontWeight.w700,
                              fontSize: widget.featured ? 18 : 15)),
                      const SizedBox(height: 3),
                      Text(widget.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: widget.foreground.withValues(alpha: 0.68),
                              fontSize: 12.5)),
                    ]),
              ),
              // Arrow
              Icon(Icons.chevron_right_rounded,
                  color: widget.foreground.withValues(alpha: 0.55), size: 26),
            ]),
          ),
        ),
      ),
    );
  }
}
