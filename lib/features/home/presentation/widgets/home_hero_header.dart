import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/background/presentation/widgets/operations_badge_button.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/i18n/locale_controller.dart';
import 'package:untitled2/core/services/help/help_topic.dart';
import 'package:untitled2/core/widgets/common/app_help_button.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/widgets/account_status_badge.dart';

class HomeHeroHeader extends StatelessWidget {
  const HomeHeroHeader({
    super.key,
    required this.onOpenWorkspaceDrawer,
    required this.onOpenOperationsPage,
    required this.localeController,
  });

  final VoidCallback onOpenWorkspaceDrawer;
  final VoidCallback onOpenOperationsPage;
  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF56E39F), Color(0xFF3D5AFE)],
                  ),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.black),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.appTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    BlocBuilder<AuthSessionBloc, AuthSessionState>(
                      builder: (context, state) {
                        return AccountStatusBadge(state: state, compact: true);
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tr.appSubtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onOpenWorkspaceDrawer,
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
              ),
              const SizedBox(width: 4),
              OperationsBadgeButton(onTap: onOpenOperationsPage),
              const SizedBox(width: 8),
              PopupMenuButton<Locale>(
                initialValue: localeController.locale,
                onSelected: localeController.setLocale,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: const Locale('en'),
                    child: Text(tr.languageEnglish),
                  ),
                  PopupMenuItem(
                    value: const Locale('ar'),
                    child: Text(tr.languageArabic),
                  ),
                ],
                child: const Icon(Icons.language_rounded, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const AppHelpButton(topic: HelpTopic.home),
            ],
          ),
          const SizedBox(height: 28),
          Text(tr.chooseA, style: Theme.of(context).textTheme.displayLarge),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF56E39F), Color(0xFF3D8BFD)],
            ).createShader(bounds),
            child: Text(
              tr.workspace,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tr.homeHeroSummary,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatPill(label: '13', sub: tr.statTools),
              const SizedBox(width: 10),
              BlocBuilder<AuthSessionBloc, AuthSessionState>(
                builder: (context, state) {
                  return _StatPill(
                    label: tr.homeStatAuthLabel,
                    sub: state is AuthSessionAuthenticated
                        ? tr.accountStatusLoggedIn
                        : tr.accountStatusGuest,
                  );
                },
              ),
              const SizedBox(width: 10),
              _StatPill(
                label: tr.homeStatProtectionLabel,
                sub: tr.homeStatAddedLabel,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: onOpenOperationsPage,
                  borderRadius: BorderRadius.circular(24),
                  child: BlocBuilder<JobQueueCubit, JobQueueState>(
                    builder: (context, state) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        state.activeJobs.isEmpty
                            ? tr.operations
                            : tr.activeJobs(state.activeJobs.length),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          Text(sub),
        ],
      ),
    );
  }
}
