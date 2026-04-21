import 'package:flutter/material.dart';
import 'package:untitled2/core/di/injection.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/services/analytics/app_analytics.dart';
import 'package:untitled2/core/services/analytics/app_analytics_event.dart';
import 'package:untitled2/core/services/help/help_content_service.dart';
import 'package:untitled2/core/services/help/help_topic.dart';

class AppHelpButton extends StatelessWidget {
  const AppHelpButton({
    super.key,
    required this.topic,
  });

  final HelpTopic topic;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.tr.commonHelp,
      onPressed: () async {
        await getIt<AppAnalytics>().log(
          AppAnalyticsEvent.helpOpened(topic: topic.name),
        );
        if (!context.mounted) {
          return;
        }
        final content =
            getIt<HelpContentService>().resolve(topic, context.tr);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          showDragHandle: true,
          builder: (sheetContext) {
            final textTheme = Theme.of(sheetContext).textTheme;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(content.title, style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(content.summary, style: textTheme.bodyMedium),
                      const SizedBox(height: 16),
                      for (var i = 0; i < content.steps.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text('${i + 1}. ${content.steps[i]}'),
                        ),
                      if (content.tips.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.tr.commonTips,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final tip in content.tips)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $tip'),
                          ),
                      ],
                      if (content.warnings.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          context.tr.commonWarnings,
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        for (final warning in content.warnings)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text('• $warning'),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      icon: const Icon(Icons.help_outline_rounded),
    );
  }
}
