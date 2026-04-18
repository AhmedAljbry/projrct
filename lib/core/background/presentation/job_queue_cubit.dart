import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:workmanager/workmanager.dart';

class JobQueueState {
  final List<BackgroundJob> activeJobs;
  final List<BackgroundJob> completedJobs;

  JobQueueState({
    this.activeJobs = const [],
    this.completedJobs = const [],
  });

  JobQueueState copyWith({
    List<BackgroundJob>? activeJobs,
    List<BackgroundJob>? completedJobs,
  }) {
    return JobQueueState(
      activeJobs: activeJobs ?? this.activeJobs,
      completedJobs: completedJobs ?? this.completedJobs,
    );
  }
}

class JobQueueCubit extends Cubit<JobQueueState> {
  final BgJobRepository _repository;
  Timer? _pollingTimer;

  JobQueueCubit(this._repository) : super(JobQueueState()) {
    _startPolling();
  }

  void _startPolling() {
    _refreshJobs();
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _refreshJobs();
    });
  }

  Future<void> _refreshJobs() async {
    if (isClosed) return;
    
    final allJobs = await _repository.getAllJobs();
    
    final active = allJobs.where((j) => 
      j.status != JobStatus.completed && 
      j.status != JobStatus.cancelled && 
      j.status != JobStatus.failed
    ).toList();
    
    final completed = allJobs.where((j) => 
      j.status == JobStatus.completed || 
      j.status == JobStatus.cancelled || 
      j.status == JobStatus.failed
    ).toList();
    
    // sorting active by queue config/date?
    active.sort((a,b) => a.queuePosition.compareTo(b.queuePosition));
    completed.sort((a,b) => b.updatedAt.compareTo(a.updatedAt)); // newest first
    
    emit(state.copyWith(activeJobs: active, completedJobs: completed));
  }

  Future<void> enqueueJob({
    required BgJobType type,
    required String sourceImagePath,
    String? maskImagePath,
    Map<String, dynamic> metadata = const {},
  }) async {
    // Generate UUID or timestamp-based ID
    final jobId = DateTime.now().millisecondsSinceEpoch.toString();
    
    await _repository.enqueueJob(
      jobId: jobId,
      toolType: type,
      sourceImagePath: sourceImagePath,
      maskImagePath: maskImagePath,
      metadata: metadata,
    );
    
    // Register WorkManager task
    Workmanager().registerOneOffTask(
      jobId, 
      "background_processing_task_$jobId",
      inputData: {'jobId': jobId},
      constraints: Constraints(
        networkType: NetworkType.connected, // requires internet
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(seconds: 10),
    );
    
    _refreshJobs();
  }

  Future<void> cancelJob(String jobId) async {
    await Workmanager().cancelByUniqueName(jobId);
    await _repository.markCancelled(jobId);
    _refreshJobs();
  }
  
  Future<void> clearCompleted() async {
      final allJobs = await _repository.getAllJobs();
      for(var j in allJobs) {
          if (j.status == JobStatus.completed || j.status == JobStatus.cancelled || j.status == JobStatus.failed) {
             await _repository.deleteJob(j.jobId);
          }
      }
      _refreshJobs();
  }

  Future<void> clearAllJobs() async {
      await Workmanager().cancelAll();
      await _repository.clearAll();
      _refreshJobs();
  }

  @override
  Future<void> close() {
    _pollingTimer?.cancel();
    return super.close();
  }
}
