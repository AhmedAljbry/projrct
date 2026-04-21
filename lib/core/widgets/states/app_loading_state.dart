import 'package:flutter/material.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';

class AppLoadingState extends StatelessWidget {
  const AppLoadingState({
    super.key,
    this.message,
  });

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message ?? context.tr.commonLoading),
        ],
      ),
    );
  }
}
