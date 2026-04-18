import 'package:flutter/material.dart';

import 'package:untitled2/core/background/presentation/widgets/operations_queue_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';

class OperationsDrawer extends StatelessWidget {
  const OperationsDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: LamaTheme.toolbarBg,
      child: SafeArea(
        child: Column(
          children: const [
            Expanded(
              child: OperationsQueueView(),
            ),
          ],
        ),
      ),
    );
  }
}
