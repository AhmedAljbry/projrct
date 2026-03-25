import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/inpainting_repository.dart';
import '../../domain/inpainting_failure.dart';
import '../../domain/inpainting_status.dart';
import 'inpainting_event.dart';
import 'inpainting_state.dart';
import 'package:untitled2/core/services/task_persistence_service.dart';
import 'package:untitled2/core/services/notification_service.dart';

class InpaintingBloc extends Bloc<InpaintingEvent, InpaintingState> {
  final InpaintingRepository repo;

  bool _cancelled = false;

  InpaintingBloc({required this.repo}) : super(InpaintingState.idle()) {
    on<InpaintingStart>(_onStart);
    on<InpaintingCancel>(_onCancel);
    on<InpaintingReset>(_onReset);
  }

  // ── Reset ───────────────────────────────────────────────────
  Future<void> _onReset(
      InpaintingReset e, Emitter<InpaintingState> emit) async {
    _cancelled = false;
    final jid = state.jobId;
    if (jid != null) {
      TaskPersistenceService().completeTask(jid);
    }
    emit(InpaintingState.idle());
  }

  // ── Cancel ──────────────────────────────────────────────────
  Future<void> _onCancel(
      InpaintingCancel e, Emitter<InpaintingState> emit) async {
    _cancelled = true;

    final jid = state.jobId;
    if (jid != null) {
      // Fire-and-forget — cancelJob never throws
      repo.cancelJob(jid);
      TaskPersistenceService().completeTask(jid);
    }

    emit(state.copyWith(
      status: InpaintingStatus.cancelled,
      failure: const InpaintingFailure(code: 'cancelled', messageKey: 'cancelled'),
      serverMessage: null,
      serverStage: null,
      serverProgress: null,
      lastUpdatedAt: DateTime.now(),
    ));
  }

  // ── Start ────────────────────────────────────────────────────
  Future<void> _onStart(
      InpaintingStart event, Emitter<InpaintingState> emit) async {
    _cancelled = false;

    // 1) Uploading
    emit(InpaintingState(
      status: InpaintingStatus.uploading,
      startedAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
    ));

    try {
      final submit = await repo.submitJob(
        image: event.imageBytes,
        mask: event.maskBytes,
      );
      if (_cancelled) return;

      // 2) Queued
      emit(state.copyWith(
        status: InpaintingStatus.queued,
        jobId: submit.jobId,
        queuePosition: submit.position,
        serverMessage: submit.message,
        serverProgress: 10,
        serverStage: 'queued',
        lastUpdatedAt: DateTime.now(),
        clearFailure: true,
      ));
      
      TaskPersistenceService().registerRunningTask(
        submit.jobId,
        'Magic Eraser processing',
      );

      // 3) Poll until completed
      await _poll(emit, submit.jobId);
      if (_cancelled) return;

      // 4) Downloading
      emit(state.copyWith(
        status: InpaintingStatus.downloading,
        serverMessage: null,
        serverStage: 'downloading',
        serverProgress: 95,
        lastUpdatedAt: DateTime.now(),
      ));

      // 5) Fetch result bytes
      final bytes = await repo.downloadResult(
        submit.jobId,
        sentImageBytes: event.imageBytes,
      );
      if (_cancelled) return;

      TaskPersistenceService().completeTask(submit.jobId);
      NotificationService().showNotification(
        id: submit.jobId.hashCode,
        title: 'Magic Eraser Complete',
        body: 'Your processing has finished successfully.',
      );

      emit(state.copyWith(
        status: InpaintingStatus.success,
        result: bytes,
        serverProgress: 100,
        serverStage: 'completed',
        lastUpdatedAt: DateTime.now(),
      ));
    } on InpaintingFailure catch (f) {
      if (_cancelled) return;
      if (state.jobId != null) TaskPersistenceService().completeTask(state.jobId!);
      emit(state.copyWith(
        status: f.code == 'timeout'
            ? InpaintingStatus.timeout
            : InpaintingStatus.failed,
        failure: f,
        lastUpdatedAt: DateTime.now(),
      ));
    } catch (_) {
      if (_cancelled) return;
      if (state.jobId != null) TaskPersistenceService().completeTask(state.jobId!);
      emit(state.copyWith(
        status: InpaintingStatus.failed,
        failure: const InpaintingFailure(code: 'unknown', messageKey: 'failed'),
        lastUpdatedAt: DateTime.now(),
      ));
    }
  }

  // ── Polling loop ─────────────────────────────────────────────
  Future<void> _poll(Emitter<InpaintingState> emit, String jobId) async {
    const interval = Duration(seconds: 2);
    const maxWait = Duration(seconds: 900);
    final started = DateTime.now();

    while (!_cancelled) {
      if (DateTime.now().difference(started) > maxWait) {
        throw const InpaintingFailure(code: 'timeout', messageKey: 'timeout');
      }

      final st = await repo.getStatus(jobId);
      if (_cancelled) return;

      emit(state.copyWith(
        pollCount: state.pollCount + 1,
        lastUpdatedAt: DateTime.now(),
        serverProgress: st.progress,
        serverStage: st.stage,
        serverMessage: st.message,
        queuePosition: st.position ?? state.queuePosition,
        status: _toUiStatus(st.status),
      ));

      if (st.isCompleted) return;
      if (st.isFailed) {
        throw const InpaintingFailure(code: 'failed', messageKey: 'failed');
      }
      if (st.isCancelled) {
        throw const InpaintingFailure(
            code: 'cancelled', messageKey: 'cancelled');
      }

      await Future.delayed(interval);
    }
  }

  InpaintingStatus _toUiStatus(String s) => switch (s) {
    'queued'     => InpaintingStatus.queued,
    'processing' => InpaintingStatus.processing,
    'completed'  => InpaintingStatus.processing, // still downloading
    'failed'     => InpaintingStatus.failed,
    'cancelled'  => InpaintingStatus.cancelled,
    _            => InpaintingStatus.processing,
  };
}
