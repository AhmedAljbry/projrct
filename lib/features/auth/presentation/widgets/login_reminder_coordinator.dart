import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_bloc.dart';
import 'package:untitled2/features/auth/presentation/bloc/auth_session_state.dart';
import 'package:untitled2/features/auth/presentation/bloc/login_reminder_cubit.dart';
import 'package:untitled2/features/auth/presentation/bloc/login_reminder_state.dart';
import 'package:untitled2/features/auth/presentation/widgets/login_reminder_sheet.dart';

class LoginReminderCoordinator extends StatefulWidget {
  const LoginReminderCoordinator({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<LoginReminderCoordinator> createState() =>
      _LoginReminderCoordinatorState();
}

class _LoginReminderCoordinatorState extends State<LoginReminderCoordinator> {
  bool _isPresentingSheet = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context
          .read<LoginReminderCubit>()
          .handleAuthState(context.read<AuthSessionBloc>().state);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AuthSessionBloc, AuthSessionState>(
          listener: (context, state) {
            context.read<LoginReminderCubit>().handleAuthState(state);
          },
        ),
        BlocListener<LoginReminderCubit, LoginReminderState>(
          listener: (context, state) async {
            if (state is! LoginReminderVisible || _isPresentingSheet) {
              return;
            }

            _isPresentingSheet = true;
            final shouldLogin = await showModalBottomSheet<bool>(
              context: context,
              useSafeArea: true,
              isDismissible: true,
              showDragHandle: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const LoginReminderSheet(),
            );
            _isPresentingSheet = false;

            if (!mounted) {
              return;
            }

            if (shouldLogin == true) {
              context.read<LoginReminderCubit>().hideReminder();
              if (GoRouterState.of(context).matchedLocation != '/login') {
                context.go('/login');
              }
              return;
            }

            await context.read<LoginReminderCubit>().dismissReminder();
          },
        ),
      ],
      child: widget.child,
    );
  }
}
