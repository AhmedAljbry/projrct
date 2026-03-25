import 'package:flutter/material.dart';
import '../../../../core/feature_flags/feature_flags.dart';

class AdsSlot extends StatelessWidget {
  final FeatureFlags flags;
  const AdsSlot({super.key, required this.flags});

  @override
  Widget build(BuildContext context) {
    if (!flags.adsEnabled) return const SizedBox.shrink();
    return const SizedBox(height: 56);
  }
}