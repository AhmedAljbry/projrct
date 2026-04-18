import 'package:shared_preferences/shared_preferences.dart';
import 'bg_job_models.dart';

class BgJobRepository {
  static const String _jobsKey = 'bg_processing_jobs';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<List<BackgroundJob>> getAllJobs() async {
    final prefs = await _prefs;
    final jobsList = prefs.getStringList(_jobsKey) ?? [];
    return jobsList.map((j) => BackgroundJob.fromJson(j)).toList();
  }

  Future<BackgroundJob?> getJob(String jobId) async {
    final jobs = await getAllJobs();
    try {
      return jobs.firstWhere((j) => j.jobId == jobId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveJob(BackgroundJob job) async {
    final prefs = await _prefs;
    final jobs = await getAllJobs();
    
    final index = jobs.indexWhere((j) => j.jobId == job.jobId);
    if (index >= 0) {
      jobs[index] = job;
    } else {
      jobs.add(job);
    }

    final jobsJsonList = jobs.map((j) => j.toJson()).toList();
    await prefs.setStringList(_jobsKey, jobsJsonList);
  }

  Future<void> deleteJob(String jobId) async {
    final prefs = await _prefs;
    final jobs = await getAllJobs();
    jobs.removeWhere((j) => j.jobId == jobId);
    
    final jobsJsonList = jobs.map((j) => j.toJson()).toList();
    await prefs.setStringList(_jobsKey, jobsJsonList);
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.remove(_jobsKey);
  }

  Future<BackgroundJob> enqueueJob({
    required String jobId,
    required BgJobType toolType,
    required String sourceImagePath,
    String? maskImagePath,
    Map<String, dynamic> metadata = const {},
  }) async {
    final now = DateTime.now();
    final jobs = await getAllJobs();
    
    final newJob = BackgroundJob(
      jobId: jobId,
      toolType: toolType,
      sourceImagePath: sourceImagePath,
      maskImagePath: maskImagePath,
      createdAt: now,
      updatedAt: now,
      status: JobStatus.pending,
      queuePosition: jobs.length + 1,
      metadata: metadata,
    );

    await saveJob(newJob);
    return newJob;
  }

  Future<void> updateJobStatus(String jobId, JobStatus status, {String? errorMessage, int? progress, String? outputImagePath}) async {
    final job = await getJob(jobId);
    if (job != null) {
      final updatedJob = job.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        errorMessage: errorMessage ?? job.errorMessage,
        progress: progress ?? job.progress,
        outputImagePath: outputImagePath ?? job.outputImagePath,
      );
      await saveJob(updatedJob);
    }
  }

  Future<void> patchJob(
    String jobId, {
    JobStatus? status,
    String? errorMessage,
    int? progress,
    String? outputImagePath,
    int? queuePosition,
    bool? isCancelled,
    Map<String, dynamic>? metadata,
  }) async {
    final job = await getJob(jobId);
    if (job == null) {
      return;
    }
    final updatedJob = job.copyWith(
      status: status ?? job.status,
      updatedAt: DateTime.now(),
      errorMessage: errorMessage ?? job.errorMessage,
      progress: progress ?? job.progress,
      outputImagePath: outputImagePath ?? job.outputImagePath,
      queuePosition: queuePosition ?? job.queuePosition,
      isCancelled: isCancelled ?? job.isCancelled,
      metadata: metadata ?? job.metadata,
    );
    await saveJob(updatedJob);
  }

  Future<void> markCancelled(String jobId) async {
    final job = await getJob(jobId);
    if (job != null) {
      final updatedJob = job.copyWith(
        isCancelled: true,
        status: JobStatus.cancelled,
        updatedAt: DateTime.now(),
      );
      await saveJob(updatedJob);
    }
  }
}
