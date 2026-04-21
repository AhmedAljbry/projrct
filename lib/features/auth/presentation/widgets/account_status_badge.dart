import 'package:flutter/material.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';

class AccountStatusBadge extends StatelessWidget {
  const AccountStatusBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  final AuthSessionState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = state is AuthSessionAuthenticated;
    final color =
        isAuthenticated ? const Color(0xFF56E39F) : const Color(0xFFFFB74D);
    final icon = isAuthenticated ? Icons.verified_user_rounded : Icons.person;
    final label =
        isAuthenticated ? context.tr.accountStatusLoggedIn : context.tr.accountStatusGuest;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 16 : 18, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
