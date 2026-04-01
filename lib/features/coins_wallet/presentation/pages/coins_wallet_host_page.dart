import 'package:coins_system/coins_system.dart';
import 'package:flutter/material.dart';

import '../../../../core/config/app_config.dart';

class CoinsWalletHostPage extends StatefulWidget {
  const CoinsWalletHostPage({
    super.key,
    required this.config,
    this.userId = demoCoinsUserId,
  });

  static const String demoCoinsUserId = 'local-demo-user';

  final AppConfig config;
  final String userId;

  @override
  State<CoinsWalletHostPage> createState() => _CoinsWalletHostPageState();
}

class _CoinsWalletHostPageState extends State<CoinsWalletHostPage> {
  late final Future<void> _setupFuture = _configureCoinsModule();

  Future<void> _configureCoinsModule() async {
    final Map<String, String> defaultHeaders = <String, String>{
      if (widget.config.apiKey != null && widget.config.apiKey!.isNotEmpty)
        'x-api-key': widget.config.apiKey!,
    };

    await configureCoinsDependencies(
      CoinsConfig(
        baseUrl: widget.config.baseUrl,
        defaultHeaders: defaultHeaders,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _setupFuture,
      builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0C0C0E),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF56E39F)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF0C0C0E),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.redAccent,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to initialize the coins module.\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return CoinsWalletPage(
          userId: widget.userId,
          onPackageSelected: (CoinPackage package) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'Selected ${package.title}. Connect your billing flow next.',
                  ),
                ),
              );
          },
        );
      },
    );
  }
}
