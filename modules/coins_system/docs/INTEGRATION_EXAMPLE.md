# Integration Example

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:coins_system/coins_module.dart';

class CoinsDemoSection extends StatefulWidget {
  const CoinsDemoSection({super.key});

  @override
  State<CoinsDemoSection> createState() => _CoinsDemoSectionState();
}

class _CoinsDemoSectionState extends State<CoinsDemoSection> {
  bool _ready = false;
  String? _userId;
  List<ProductOffer> _products = const [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final ready = await CoinsSystem.initialize(
      firebaseApp: Firebase.app(),
      config: const CoinsSystemConfig(
        functionsRegion: 'us-central1',
        adMobRewardedUnitId: 'ca-app-pub-xxxxxxxxxxxxxxxx/rewarded-unit',
        googleServerClientId: 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com',
        androidPackageName: 'com.example.app',
        productCoins: {
          'coins_50': 50,
          'coins_120': 120,
        },
      ),
    );
    final products = ready ? await CoinsSystem.purchaseService.loadProducts() : const <ProductOffer>[];
    if (mounted) {
      setState(() {
        _ready = ready;
        _products = products;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Text('Coins module unavailable');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GoogleSignInButton(
          onCompleted: () async {
            setState(() {
              _userId = CoinsSystem.authService.currentUserId;
            });
          },
        ),
        const SizedBox(height: 12),
        if (_userId != null) ...<Widget>[
          CoinsStatusBanner(
            walletStream: CoinsSystem.coinsService.watchWallet(_userId!),
          ),
          const SizedBox(height: 12),
          RewardedAdButton(userId: _userId!),
          const SizedBox(height: 12),
          SizedBox(
            height: 280,
            child: ProductOffersList(
              products: _products,
              onBuy: (product) async {
                await CoinsSystem.purchaseService.buyProduct(product.productId);
              },
            ),
          ),
        ],
      ],
    );
  }
}
```

This pattern keeps the existing app untouched:

- no navigation changes
- no state-management migration
- no dependency on the module unless imported intentionally
