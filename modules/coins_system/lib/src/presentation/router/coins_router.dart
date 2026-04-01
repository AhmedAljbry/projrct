import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/coins_models.dart';
import '../pages/coins_wallet_page.dart';

class CoinsRoutes {
  const CoinsRoutes._();

  static const String wallet = '/coins/:userId';

  static String walletPath(String userId) => '/coins/$userId';
}

List<RouteBase> buildCoinsRoutes({
  ValueChanged<CoinPackage>? onPackageSelected,
}) {
  return <RouteBase>[
    GoRoute(
      path: CoinsRoutes.wallet,
      builder: (BuildContext context, GoRouterState state) {
        final String userId = state.pathParameters['userId'] ?? '';
        return CoinsWalletPage(
          userId: userId,
          onPackageSelected: onPackageSelected,
        );
      },
    ),
  ];
}
