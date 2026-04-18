import 'package:flutter/material.dart';

import 'package:untitled2/core/background/presentation/widgets/operations_queue_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

class OperationsPage extends StatelessWidget {
  const OperationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Scaffold(
      backgroundColor: LamaTheme.background,
      appBar: AppBar(
        backgroundColor: LamaTheme.toolbarBg,
        title: Text(
          l10n.get('operations_center'),
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: const SafeArea(
        child: OperationsQueueView(),
      ),
    );
  }
}
