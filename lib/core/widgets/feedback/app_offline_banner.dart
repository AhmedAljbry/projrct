import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/i18n/app_localizations_x.dart';
import 'package:untitled2/core/services/connectivity/connectivity_cubit.dart';
import 'package:untitled2/core/services/connectivity/connectivity_state.dart';

class AppOfflineBanner extends StatelessWidget {
  const AppOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
      builder: (context, state) {
        if (state.isOnline) {
          return const SizedBox.shrink();
        }
        return Material(
          color: const Color(0xFF6D1B1B),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      context.tr.offlineBannerMessage,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  TextButton(
                    onPressed: context.read<ConnectivityCubit>().refresh,
                    child: Text(context.tr.commonRetry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
