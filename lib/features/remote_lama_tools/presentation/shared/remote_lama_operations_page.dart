import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:untitled2/core/background/presentation/job_queue_cubit.dart';
import 'package:untitled2/core/background/presentation/widgets/operations_queue_view.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/lama_theme_colors.dart';
import 'package:untitled2/features/remote_lama_tools/presentation/shared/remote_lama_result_page.dart';

class RemoteLamaOperationsPage extends StatefulWidget {
  const RemoteLamaOperationsPage({
    super.key,
    this.focusJobId,
    this.resultTitle,
    this.originalBytes,
    this.lockToFocusedFlow = false,
    this.disableOtherNavigation = false,
  });

  final String? focusJobId;
  final String? resultTitle;
  final Uint8List? originalBytes;
  final bool lockToFocusedFlow;
  final bool disableOtherNavigation;

  @override
  State<RemoteLamaOperationsPage> createState() =>
      _RemoteLamaOperationsPageState();
}

class _RemoteLamaOperationsPageState extends State<RemoteLamaOperationsPage> {
  bool _openedFocusedResult = false;

  Future<void> _openJobResult(BackgroundJob job) async {
    if (job.outputImagePath == null) {
      return;
    }

    final resultBytes = await File(job.outputImagePath!).readAsBytes();
    final originalBytes = await _resolveOriginalBytes(job);
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RemoteLamaResultPage(
          title: _resolveResultTitle(job),
          resultBytes: resultBytes,
          originalBytes: originalBytes,
          onReset: () {},
          showOperationsShortcut: !widget.lockToFocusedFlow,
        ),
      ),
    );
  }

  Future<Uint8List?> _resolveOriginalBytes(BackgroundJob job) async {
    if (widget.focusJobId == job.jobId && widget.originalBytes != null) {
      return widget.originalBytes;
    }

    final sourceFile = File(job.sourceImagePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    return sourceFile.readAsBytes();
  }

  String _resolveResultTitle(BackgroundJob job) {
    if (widget.focusJobId == job.jobId && widget.resultTitle != null) {
      return widget.resultTitle!;
    }

    return switch (job.toolType) {
      BgJobType.heal => 'Heal Result',
      BgJobType.cleanEdges => 'Clean Edges Result',
      BgJobType.repairDamage => 'Repair Damage Result',
      BgJobType.descratch => 'Descratch Result',
      BgJobType.background => 'Background Cleanup Result',
      BgJobType.expandCanvas => 'Expand Canvas Result',
      BgJobType.magic => 'Magic Result',
    };
  }

  void _maybeOpenFocusedResult(JobQueueState state) {
    if (widget.disableOtherNavigation) {
      return;
    }
    final focusJobId = widget.focusJobId;
    if (_openedFocusedResult || focusJobId == null) {
      return;
    }

    BackgroundJob? focusedJob;
    try {
      focusedJob = [...state.activeJobs, ...state.completedJobs]
          .firstWhere((job) => job.jobId == focusJobId);
    } catch (_) {
      focusedJob = null;
    }

    if (focusedJob == null || focusedJob.status != JobStatus.completed) {
      return;
    }

    _openedFocusedResult = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _openJobResult(focusedJob!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JobQueueCubit(BgJobRepository()),
      child: BlocListener<JobQueueCubit, JobQueueState>(
        listener: (context, state) => _maybeOpenFocusedResult(state),
        child: Scaffold(
          backgroundColor: LamaTheme.background,
          appBar: AppBar(
            backgroundColor: LamaTheme.toolbarBg,
            title: const Text('Operations'),
          ),
          body: SafeArea(
            child: OperationsQueueView(
              jobIdFilter: widget.lockToFocusedFlow ? widget.focusJobId : null,
              onJobTap: widget.disableOtherNavigation
                  ? null
                  : (job) {
                      final canOpenJob = !widget.lockToFocusedFlow ||
                          widget.focusJobId == null ||
                          job.jobId == widget.focusJobId;
                      if (canOpenJob && job.status == JobStatus.completed) {
                        _openJobResult(job);
                      }
                    },
            ),
          ),
        ),
      ),
    );
  }
}
