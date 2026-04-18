import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:workmanager/workmanager.dart';
import 'package:untitled2/core/background/bg_job_models.dart';
import 'package:untitled2/core/background/bg_job_repository.dart';
import 'package:untitled2/features/remote_lama_tools/data/datasources/lama_remote_data_source.dart';
import 'package:untitled2/features/remote_lama_tools/data/repositories/lama_repository_impl.dart';
import 'package:untitled2/features/remote_lama_tools/domain/entities/lama_entities.dart';
import 'package:untitled2/features/remote_lama_tools/domain/usecases/lama_usecases.dart';
import 'package:untitled2/core/config/app_config.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    void log(String message) {
      debugPrint('[BGWorker] $message');
    }

    log('Worker started: taskName=$taskName inputData=$inputData');
    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    
    // Notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'bg_job_channel',
      'Background Tasks',
      description: 'Used for background processing jobs',
      importance: Importance.low, // Low importance for progress
    );
    
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    final repo = BgJobRepository();

    if (inputData == null || !inputData.containsKey('jobId')) {
      log('Worker stopped: missing jobId in inputData');
      return Future.value(false);
    }
    
    final jobId = inputData['jobId'];
    final job = await repo.getJob(jobId);
    if (job == null || job.isCancelled) {
      log('Worker stopped: job missing or cancelled before start. jobId=$jobId');
      return Future.value(true);
    }

    log('Loaded job: id=${job.jobId} type=${job.toolType.name} source=${job.sourceImagePath} mask=${job.maskImagePath}');

    final int notificationId = jobId.hashCode;

    void updateNotification(String msg, int progress, {bool isError = false, bool isCompleted = false}) {
      flutterLocalNotificationsPlugin.show(
        notificationId,
        'Processing Image',
        msg,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            showProgress: !isError && !isCompleted,
            maxProgress: 100,
            progress: progress,
            ongoing: !isError && !isCompleted,
            importance: (!isError && !isCompleted) ? Importance.low : Importance.high,
          ),
        ),
      );
    }
    
    try {
      await repo.updateJobStatus(jobId, JobStatus.preparing);
      log('Job $jobId -> preparing');
      updateNotification('Preparing image...', 5);

      // IMPORTANT: Need to intialize dependencies since we're in a new isolate.
      // Currently using mock AppConfig or fetching from SharedPreferences in a real app.
      // Assuming InpaintingApi defaults are sufficient or need specific config
      final appConfig = AppConfig.fromEnvironment();
      
      final File sourceImage = File(job.sourceImagePath);
      final File maskImage = File(job.maskImagePath ?? ''); 
      // check if exist
      if (!sourceImage.existsSync() || (job.maskImagePath != null && !maskImage.existsSync())) {
        throw Exception('Source or mask image missing');
      }

      final sourceBytes = await sourceImage.readAsBytes();
      final maskBytes = job.maskImagePath != null ? await maskImage.readAsBytes() : null;

      log('Read files for jobId=$jobId sourceBytes=${sourceBytes.length} maskBytes=${maskBytes?.length ?? 0}');

      await repo.updateJobStatus(jobId, JobStatus.uploading);
      log('Job $jobId -> uploading to remote API ${appConfig.baseUrl}');
      updateNotification('Uploading...', 15);

      Uint8List? resultBytes;

      if (job.toolType == BgJobType.magic || 
          job.toolType == BgJobType.heal || 
          job.toolType == BgJobType.cleanEdges) {
        
        final dataSource = LamaRemoteDataSourceImpl(
          baseUrl: appConfig.baseUrl,
          apiKey: appConfig.apiKey ?? '',
          ownerId: appConfig.ownerId ?? 'app-user',
          client: http.Client(),
        );
        final lamaRepo = LamaRepositoryImpl(remoteDataSource: dataSource);
        final submitJobUseCase = SubmitJobUseCase(lamaRepo);
        final pollJobStatusUseCase = PollJobStatusUseCase(lamaRepo);
        final getJobResultUseCase = GetJobResultUseCase(lamaRepo);

        String remoteJobId;
        if (job.toolType == BgJobType.magic) {
          log('Submitting magic inpainting job to remote API');
          remoteJobId = await submitJobUseCase.execute(RepairDamageOptions(
            imageBytes: sourceBytes,
            imageName: 'magic_bg.png',
            maskBytes: maskBytes!,
            maskName: 'mask_bg.png',
          ));
        } else if (job.toolType == BgJobType.heal) {
          int radius = job.metadata['healRadius'] ?? 0;
          log('Submitting heal job to remote API with radius=$radius');
          remoteJobId = await submitJobUseCase.execute(HealRegionOptions(
            imageBytes: sourceBytes,
            imageName: 'heal_bg.png',
            maskBytes: maskBytes!,
            maskName: 'mask_bg.png',
            healRadius: radius
          ));
        } else {
          int edgeRadius = job.metadata['edgeRadius'] ?? 4;
          log('Submitting clean-edges job to remote API with edgeRadius=$edgeRadius');
          remoteJobId = await submitJobUseCase.execute(CleanEdgesOptions(
            imageBytes: sourceBytes,
            imageName: 'clean_bg.png',
            maskBytes: maskBytes!,
            maskName: 'mask_bg.png',
            edgeRadius: edgeRadius
          ));
        }

        await repo.updateJobStatus(jobId, JobStatus.processing);
        log('Remote job accepted: localJobId=$jobId remoteJobId=$remoteJobId');
        updateNotification('Processing ${job.toolType.name}...', 50);

        LamaJobStatus finalStatus = LamaJobStatus(
          jobId: remoteJobId,
          status: 'queued',
          progress: 0,
          message: '',
        );
        await for (final status in pollJobStatusUseCase.execute(remoteJobId)) {
           finalStatus = status;
           log(
             'Remote progress: localJobId=$jobId remoteJobId=$remoteJobId status=${status.status} progress=${status.progress}% message=${status.message}',
           );
           if (status.isCompleted || status.isFailed) {
              break;
           }
           updateNotification('Processing ${job.toolType.name}...', status.progress);
           await repo.updateJobStatus(jobId, JobStatus.processing, progress: status.progress);
           
           final currentJob = await repo.getJob(jobId);
           if (currentJob != null && currentJob.isCancelled) {
              log('Worker noticed cancellation during processing for jobId=$jobId');
              return Future.value(true);
           }
        }

        if (finalStatus.isFailed) {
          throw Exception('Remote job failed or cancelled: ${finalStatus.error}');
        }

        await repo.updateJobStatus(jobId, JobStatus.processing, progress: 95);
        log('Downloading remote result for localJobId=$jobId remoteJobId=$remoteJobId');
        updateNotification('Downloading result...', 95);
        resultBytes = await getJobResultUseCase.execute(remoteJobId);
        log('Downloaded result for jobId=$jobId (${resultBytes.length} bytes)');
      }

      if (resultBytes != null) {
        // save result
        final outputPath = '${sourceImage.parent.path}/out_$jobId.png';
        final outFile = File(outputPath);
        await outFile.writeAsBytes(resultBytes);
        log('Saved output for jobId=$jobId at $outputPath');
        
        await repo.updateJobStatus(jobId, JobStatus.completed, progress: 100, outputImagePath: outputPath);
        log('Job $jobId -> completed');
        updateNotification('Completed! Tap to view.', 100, isCompleted: true);
        return Future.value(true);
      } else {
        throw Exception('Result bytes null');
      }

    } catch (e) {
       log('Worker failed for jobId=$jobId error=$e');
       await repo.updateJobStatus(jobId, JobStatus.failed, errorMessage: e.toString());
       updateNotification('Processing failed', 0, isError: true);
       
       if (job.retryCount < job.maxRetries) {
          // workmanager will retry if we throw or return false 
          // (assuming exponential backoff is set during registration)
          return Future.value(false); 
       }
       return Future.value(true); // Stop retrying
    }
  });
}
