import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/background/presentation/pages/operations_page.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart';
import 'package:untitled2/core/services/feedback/app_feedback_message.dart';
import 'package:untitled2/core/services/feedback/user_feedback_service.dart';
import 'package:untitled2/core/services/permissions/permission_ux_service.dart';
import 'package:untitled2/features/ai_object_copy_paste/ai_object_copy_paste.dart';
import 'package:untitled2/features/ai_perspective_studio/presentation/screens/perspective_studio_screen.dart';
import 'package:untitled2/features/blur_photo/presentation/pages/blur_photo_page.dart';
import 'package:untitled2/features/home/presentation/widgets/home_copy.dart';
import 'package:untitled2/features/home/presentation/widgets/home_hero_header.dart';
import 'package:untitled2/features/home/presentation/widgets/studio_navigation_drawer.dart';
import 'package:untitled2/features/inpainting/presentation/inpainting_flow_shell.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/pages/remote_lama_flow_shell.dart';
import 'package:untitled2/features/smart_retouch/presentation/screens/smart_retouch_screen.dart';
import 'package:untitled2/shared/widgets/feature_card_widget.dart';
import 'package:untitled2/vv/blemish_remover_screen.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _picker = ImagePicker();
  final _analytics = getIt<AppAnalytics>();
  final _feedback = getIt<UserFeedbackService>();
  final _permissionUx = getIt<PermissionUxService>();
  bool _loading = false;
  late final AnimationController _heroAnim;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _analytics.log(AppAnalyticsEvent.screenView(screenName: 'home'));
    _heroAnim = AnimationController(
      vsync: this,
      duration:
          const Duration(milliseconds: AppConstants.heroAnimationDurationMs),
    )..forward();
    _fadeIn = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<BgJobRepository>(create: (_) => BgJobRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => JobQueueCubit(context.read<BgJobRepository>()),
          ),
        ],
        child: Scaffold(
          key: _scaffoldKey,
          drawer: StudioNavigationDrawer(
            onOpenOperations: _openOperationsPage,
          ),
          backgroundColor: const Color(0xFF0C0C0E),
          body: SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF56E39F),
                      ),
                    )
                  : CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: HomeHeroHeader(
                            onOpenWorkspaceDrawer: () {
                              _scaffoldKey.currentState?.openDrawer();
                            },
                            onOpenOperationsPage: _openOperationsPage,
                            localeController: widget.localeController,
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: _buildEssentialsPanel(),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                          sliver: SliverList(
                            delegate:
                                SliverChildListDelegate(_buildFeatureCards()),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEssentialsPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final twoColumns = constraints.maxWidth > 760;
          final width = twoColumns
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              SizedBox(width: width, child: _buildStorageCard()),
              SizedBox(width: width, child: _buildGuestCard()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStorageCard() {
    return FutureBuilder<PermissionStatus>(
      future: _galleryPermissionStatus(),
      builder: (context, snapshot) {
        final status = snapshot.data;
        final isGranted =
            status?.isGranted == true || status?.isLimited == true;
        return _WorkspaceCard(
          icon: isGranted
              ? Icons.photo_library_rounded
              : Icons.perm_media_rounded,
          title: homeText(
            context,
            ar: 'الوصول للصور',
            en: 'Photo access',
          ),
          subtitle: homeText(
            context,
            ar: 'فعّل صلاحية التخزين مرة واحدة حتى تختار الصور بسرعة داخل الأدوات.',
            en: 'Enable storage permission once so tools can pick images quickly.',
          ),
          accent: isGranted ? const Color(0xFF56E39F) : const Color(0xFFFFB74D),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _InfoPill(
                label: isGranted
                    ? homeText(
                        context,
                        ar: 'الصلاحية مفعلة',
                        en: 'Permission enabled',
                      )
                    : homeText(
                        context,
                        ar: 'بانتظار الموافقة',
                        en: 'Approval needed',
                      ),
                color: isGranted
                    ? const Color(0xFF56E39F)
                    : const Color(0xFFFFB74D),
              ),
              FilledButton.icon(
                onPressed: _requestStoragePermission,
                icon: Icon(
                  isGranted ? Icons.verified_rounded : Icons.check_rounded,
                ),
                label: Text(
                  isGranted
                      ? homeText(
                          context,
                          ar: 'إعادة الفحص',
                          en: 'Check again',
                        )
                      : homeText(
                          context,
                          ar: 'موافقة على الصلاحية',
                          en: 'Approve permission',
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestCard() {
    return _WorkspaceCard(
      icon: Icons.person_outline_rounded,
      title: homeText(
        context,
        ar: 'استخدام بدون حساب',
        en: 'Use without account',
      ),
      subtitle: homeText(
        context,
        ar: 'التطبيق يعمل مباشرة من أول فتح، والحساب صار خيارًا من الدرج فقط.',
        en: 'The app now works right away on first open, and account access lives in the drawer.',
      ),
      accent: const Color(0xFF3D8BFD),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _FeatureChip(
            label: homeText(
              context,
              ar: 'الأدوات متاحة',
              en: 'Tools ready',
            ),
          ),
          _FeatureChip(
            label: homeText(
              context,
              ar: 'الدخول اختياري',
              en: 'Sign in optional',
            ),
          ),
          OutlinedButton.icon(
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            icon: const Icon(Icons.menu_open_rounded),
            label: Text(
              homeText(
                context,
                ar: 'فتح الدرج',
                en: 'Open drawer',
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatureCards() {
    final tr = context.tr;
    return [
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.smartRetouchTitle,
        subtitle: tr.smartRetouchSubtitle,
        icon: Icons.auto_fix_high_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF1E88E5), Color(0xFF0D47A1)],
        ),
        accentColor: const Color(0xFF1E88E5),
        onTap: () => _trackFeatureTap(
          'smart_retouch',
          () => _pickAndNavigateUi(
            (image) => SmartRetouchScreen(initialImage: image, onApply: (_) {}),
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
        ),
        accentColor: const Color(0xFFFFB300),
        onTap: () => _trackFeatureTap(
          'magic_eraser',
          () => Navigator.push(
            context,
            _slide(InpaintingFlowShell(config: widget.config)),
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiObjectCopyPasteTitle,
        subtitle: tr.aiObjectCopyPasteSubtitle,
        icon: Icons.content_paste_go_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
        ),
        accentColor: const Color(0xFFAB47BC),
        onTap: () => _trackFeatureTap(
          'ai_object_copy_paste',
          () => Navigator.push(
            context,
            _slide(const AiObjectCopyPastePage()),
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.blemishRemoverTitle,
        subtitle: tr.blemishRemoverSubtitle,
        icon: Icons.face_retouching_natural_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFFE91E8C), Color(0xFF880E5F)],
        ),
        accentColor: const Color(0xFFE91E8C),
        onTap: () => _trackFeatureTap(
          'blemish_remover',
          () => _pickAndNavigateUi(
            (image) =>
                BlemishRemoverScreen(sourceImage: image, onApply: (_) {}),
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
        ),
        accentColor: const Color(0xFF00B0FF),
        onTap: () => _trackFeatureTap(
          'perspective_studio',
          () => _pickAndNavigateUi(
            (image) => PerspectiveStudioScreen(
              initialImage: image,
              onApply: (_) {},
              onClose: () => Navigator.of(context).maybePop(),
            ),
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
        ),
        accentColor: const Color(0xFFFF6B6B),
        onTap: () => _trackFeatureTap(
          'blur_photo',
          () => _pickAndNavigateUi(
            (image) => BlurPhotoPage(
              initialImage: image,
              onApply: (_) {},
              onClose: () => Navigator.of(context).maybePop(),
            ),
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
        ),
        accentColor: const Color(0xFF00E5FF),
        onTap: () => _trackFeatureTap(
          'heal_region',
          () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/heal',
            ),
          ),
        ),
      ),
      const SizedBox(height: 16),
      FeatureCardWidget(
        title: tr.aiCleanEdgesTitle,
        subtitle: tr.aiCleanEdgesSubtitle,
        icon: Icons.blur_on_rounded,
        gradient: const LinearGradient(
          colors: [Color(0xFF7AF5FF), Color(0xFF167C80)],
        ),
        accentColor: const Color(0xFF7AF5FF),
        onTap: () => _trackFeatureTap(
          'clean_edges',
          () => _pickAndNavigateBytes(
            (bytes) => RemoteLamaFlowShell(
              initialImage: bytes,
              initialRoute: '/lama/clean',
            ),
          ),
        ),
      ),
    ];
  }

  Future<void> _trackFeatureTap(String feature, VoidCallback action) async {
    await _analytics.log(AppAnalyticsEvent.featureUsed(feature: feature));
    action();
  }

  Future<void> _pickAndNavigateUi(Widget Function(ui.Image) builder) async {
    final connectivityCubit = context.read<ConnectivityCubit>();
    final canUseNetwork = await connectivityCubit.canUseNetworkAction();
    if (!canUseNetwork) {
      _feedback.showWarning(AppMessageKey.noInternetConnection);
      return;
    }
    if (!mounted) {
      return;
    }
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    if (file == null) {
      return;
    }
    await _analytics.log(AppAnalyticsEvent.imageImported(source: 'gallery'));
    setState(() => _loading = true);
    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      Navigator.push(context, _slide(builder(frame.image)));
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
      _feedback.showError(AppMessageKey.failedToLoad);
    }
  }

  Future<void> _pickAndNavigateBytes(Widget Function(Uint8List) builder) async {
    final connectivityCubit = context.read<ConnectivityCubit>();
    final canUseNetwork = await connectivityCubit.canUseNetworkAction();
    if (!canUseNetwork) {
      _feedback.showWarning(AppMessageKey.noInternetConnection);
      return;
    }
    if (!mounted) {
      return;
    }
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null) {
      return;
    }
    await _analytics.log(AppAnalyticsEvent.imageImported(source: 'gallery'));
    setState(() => _loading = true);
    try {
      final bytes = await file.readAsBytes();
      if (!mounted) {
        return;
      }
      setState(() => _loading = false);
      Navigator.push(context, _slide(builder(bytes)));
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
      _feedback.showError(AppMessageKey.failedToLoad);
    }
  }

  Route<T> _slide<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        );
      },
    );
  }

  void _openOperationsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OperationsPage()),
    );
  }

  Future<PermissionStatus> _galleryPermissionStatus() {
    return (Platform.isIOS ? Permission.photos : Permission.storage).status;
  }

  Future<void> _requestStoragePermission() async {
    await _permissionUx.ensureGalleryPermission(context);
    if (mounted) {
      setState(() {});
    }
  }
}

class _WorkspaceCard extends StatelessWidget {
  const _WorkspaceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF56E39F).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: const Color(0xFF56E39F),
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
