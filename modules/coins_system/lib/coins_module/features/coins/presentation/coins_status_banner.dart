import 'package:flutter/material.dart';

import '../../../models/coins_user.dart';

class CoinsStatusBanner extends StatelessWidget {
  const CoinsStatusBanner({
    super.key,
    required this.walletStream,
  });

  final Stream<CoinsUser> walletStream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<CoinsUser>(
      stream: walletStream,
      builder: (context, snapshot) {
        final coins = snapshot.data?.coins ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.monetization_on, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                '$coins coins',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        );
      },
    );
  }
}
