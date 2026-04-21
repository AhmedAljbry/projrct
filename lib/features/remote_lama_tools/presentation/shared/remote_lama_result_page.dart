import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_result_viewer.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_operations_page.dart';

class RemoteLamaResultPage extends StatelessWidget {
  const RemoteLamaResultPage({
    super.key,
    required this.title,
    required this.resultBytes,
    required this.originalBytes,
    required this.onReset,
    this.onRetry,
    this.showOperationsShortcut = true,
  });

  final String title;
  final Uint8List resultBytes;
  final Uint8List? originalBytes;
  final VoidCallback onReset;
  final VoidCallback? onRetry;
  final bool showOperationsShortcut;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LamaTheme.background,
      appBar: AppBar(
        backgroundColor: LamaTheme.toolbarBg,
        title: Text(title),
        actions: [
          if (showOperationsShortcut)
            IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const RemoteLamaOperationsPage(),
                ),
              ),
              icon: const Icon(Icons.dashboard_customize_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: LamaResultViewer(
          resultBytes: resultBytes,
          originalBytes: originalBytes,
          onReset: () {
            onReset();
            Navigator.of(context).pop();
          },
          onRetry: onRetry == null
              ? null
              : () {
                  onRetry!();
                  Navigator.of(context).pop();
                },
        ),
      ),
    );
  }
}
