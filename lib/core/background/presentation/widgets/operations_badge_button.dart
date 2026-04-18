import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/ui/AppL10n.dart';

class OperationsBadgeButton extends StatelessWidget {
  const OperationsBadgeButton({
    super.key,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return BlocBuilder<JobQueueCubit, JobQueueState>(
      builder: (context, state) {
        final activeCount = state.activeJobs.length;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onTap,
              icon: Icon(Icons.dashboard_customize_rounded, color: iconColor),
              tooltip: l10n.get('operations_label'),
            ),
            if (activeCount > 0)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF56E39F),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    activeCount > 9 ? '9+' : '$activeCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
