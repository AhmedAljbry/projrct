import 'package:flutter/material.dart';

import 'app_empty_state.dart';

class AppOfflineState extends StatelessWidget {
  const AppOfflineState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return AppStateScaffold(
      icon: Icons.wifi_off_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
