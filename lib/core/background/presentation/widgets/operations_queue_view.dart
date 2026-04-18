import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/ui/AppL10n.dart';
import 'package:untitled2/inpainting/presentation/widgets/inpainting_studio_chrome.dart';

class OperationsQueueView extends StatelessWidget {
  const OperationsQueueView({
    super.key,
    this.showHeader = true,
    this.compact = false,
  });

  final bool showHeader;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return BlocBuilder<JobQueueCubit, JobQueueState>(
      builder: (context, state) {
        if (state.activeJobs.isEmpty && state.completedJobs.isEmpty) {
          return Center(
            child: Text(
              l10n.get('operations_none'),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) _OperationsHeader(state: state),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 12 : 16,
                  vertical: compact ? 8 : 12,
                ),
                children: [
                  if (state.activeJobs.isNotEmpty) ...[
                    _SectionLabel(label: l10n.get('operations_running')),
                    ...state.activeJobs.map((job) => _OperationTile(job: job)),
                  ],
                  if (state.completedJobs.isNotEmpty) ...[
                    _SectionLabel(label: l10n.get('operations_history')),
                    ...state.completedJobs.map((job) => _OperationTile(job: job)),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _OperationsHeader extends StatelessWidget {
  const _OperationsHeader({required this.state});

  final JobQueueState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 14, 8),
      child: Row(
        children: [
          const Icon(
            Icons.dashboard_customize_rounded,
            color: Color(0xFF56E39F),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.get('operations_label'),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
          if (state.completedJobs.isNotEmpty)
            TextButton(
              onPressed: () => context.read<JobQueueCubit>().clearCompleted(),
              child: Text(
                l10n.get('operations_clear_finished'),
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  const _OperationTile({required this.job});

  final BackgroundJob job;

  @override
  Widget build(BuildContext context) {
    final l10n = AppL10n.of(context);
    final statusColor = switch (job.status) {
      JobStatus.pending || JobStatus.queued || JobStatus.preparing => Colors.orangeAccent,
      JobStatus.uploading || JobStatus.processing => InpaintingStudioTheme.mint,
      JobStatus.completed => InpaintingStudioTheme.cyan,
      JobStatus.failed => Colors.redAccent,
      JobStatus.cancelled => Colors.grey,
      JobStatus.retryWaiting => Colors.amber,
    };

    final statusIcon = switch (job.status) {
      JobStatus.pending || JobStatus.queued || JobStatus.preparing => Icons.schedule_rounded,
      JobStatus.uploading || JobStatus.processing => Icons.autorenew_rounded,
      JobStatus.completed => Icons.check_circle_rounded,
      JobStatus.failed => Icons.error_rounded,
      JobStatus.cancelled => Icons.cancel_rounded,
      JobStatus.retryWaiting => Icons.refresh_rounded,
    };

    final isActive = switch (job.status) {
      JobStatus.pending ||
      JobStatus.queued ||
      JobStatus.preparing ||
      JobStatus.uploading ||
      JobStatus.processing ||
      JobStatus.retryWaiting => true,
      _ => false,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(
              File(job.outputImagePath ?? job.sourceImagePath),
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 50,
                height: 50,
                color: Colors.white10,
                child: const Icon(Icons.image_rounded, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 15, color: statusColor),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.bgToolName(job.toolType.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      '${job.progress}%',
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _statusText(context, job),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (job.progress.clamp(0, 100)) / 100,
                      minHeight: 5,
                      backgroundColor: Colors.white12,
                      valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isActive)
            IconButton(
              onPressed: () => context.read<JobQueueCubit>().cancelJob(job.jobId),
              icon: const Icon(Icons.close_rounded, color: Colors.white54),
            ),
        ],
      ),
    );
  }

  String _statusText(BuildContext context, BackgroundJob job) {
    final message = job.errorMessage?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    return AppL10n.of(context).bgJobStatusName(job.status.name);
  }
}
