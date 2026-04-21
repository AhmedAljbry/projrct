import 'package:flutter/material.dart';

import 'app_empty_state.dart';

class AppPermissionState extends StatelessWidget {
  const AppPermissionState({
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
      icon: Icons.lock_outline_rounded,
      title: title,
      description: description,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
