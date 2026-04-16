import 'package:flutter/material.dart';

import '../../../core/coins_system.dart';

class GoogleSignInButton extends StatefulWidget {
  const GoogleSignInButton({
    super.key,
    this.onCompleted,
    this.label = 'Sign in with Google',
  });

  final Future<void> Function()? onCompleted;
  final String label;

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _loading
          ? null
          : () async {
              setState(() => _loading = true);
              await CoinsSystem.authService.signInWithGoogle();
              if (widget.onCompleted != null) {
                await widget.onCompleted!.call();
              }
              if (mounted) {
                setState(() => _loading = false);
              }
            },
      icon: const Icon(Icons.login),
      label: Text(_loading ? 'Signing in...' : widget.label),
    );
  }
}
