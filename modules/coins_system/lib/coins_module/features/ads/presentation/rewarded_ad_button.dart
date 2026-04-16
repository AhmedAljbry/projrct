import 'package:flutter/material.dart';

import '../../../core/coins_system.dart';
import '../../../models/reward_result.dart';

class RewardedAdButton extends StatefulWidget {
  const RewardedAdButton({
    super.key,
    required this.userId,
    this.onRewarded,
  });

  final String userId;
  final ValueChanged<RewardResult>? onRewarded;

  @override
  State<RewardedAdButton> createState() => _RewardedAdButtonState();
}

class _RewardedAdButtonState extends State<RewardedAdButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              final result =
                  await CoinsSystem.adsService.showRewardedAdAndClaim(
                userId: widget.userId,
              );
              widget.onRewarded?.call(result);
              if (mounted) {
                setState(() => _loading = false);
              }
            },
      child: Text(_loading ? 'Loading ad...' : 'Watch ad for coins'),
    );
  }
}
