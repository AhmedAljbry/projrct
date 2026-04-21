import 'package:flutter/material.dart';
import 'package:untitled2/core/constants/app_constants.dart';
import 'package:untitled2/core/services/help/help_topic.dart';
import 'package:untitled2/core/widgets/common/app_help_button.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.helpTopic,
    this.footer,
    this.drawer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final HelpTopic helpTopic;
  final Widget? footer;
  final Widget? drawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: drawer,
      body: Stack(
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF05070C),
                  Color(0xFF111827),
                  Color(0xFF031A12)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox.expand(),
          ),
          SafeArea(
            child: Stack(
              children: [
                if (drawer != null)
                  PositionedDirectional(
                    start: 8,
                    top: 8,
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) {
                            return IconButton(
                              onPressed: Scaffold.of(context).openDrawer,
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                              ),
                            );
                          },
                        ),
                        AppHelpButton(topic: helpTopic),
                      ],
                    ),
                  ),
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppConstants.authHorizontalPadding,
                      vertical: AppConstants.authVerticalPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: AppConstants.authCardMaxWidth,
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.24),
                              blurRadius: 28,
                              offset: const Offset(0, 14),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF56E39F),
                                      Color(0xFF3D8BFD),
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome_rounded,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(title, style: theme.textTheme.displayMedium),
                              const SizedBox(height: 10),
                              Text(subtitle, style: theme.textTheme.bodyLarge),
                              const SizedBox(height: 28),
                              child,
                              if (footer != null) ...[
                                const SizedBox(height: 20),
                                footer!,
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
