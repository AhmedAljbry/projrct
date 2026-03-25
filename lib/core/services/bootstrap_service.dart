/*
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lama/core/services/notification_service.dart';
import 'package:lama/core/services/task_persistence_service.dart';
import 'package:lama/core/services/update_service.dart';

enum BootstrapResult {
  updateRequired,
  onboarding,
  home,
}

class BootstrapService {
  final SharedPreferences _prefs;
  final TaskPersistenceService taskPersistence = TaskPersistenceService();
  final NotificationService notificationService = NotificationService();

  BootstrapService(this._prefs) {
    taskPersistence.init(_prefs);
  }

  Future<BootstrapResult> initialize() async {
    // 1. Initialize core non-UI services
    await notificationService.initialize();
    
    // Request notification permissions gracefully
    await notificationService.requestPermissions();

    // 2. Check for interrupted tasks
    final interrupted = taskPersistence.getInterruptedTasks();
    if (interrupted.isNotEmpty) {
      for (int i = 0; i < interrupted.length; i++) {
        final taskId = interrupted[i];
        final desc = taskPersistence.getTaskDescription(taskId) ?? 'A task';
        
        // Ensure notifications are delivered for interrupted tasks
        await notificationService.showNotification(
          id: 1000 + i, // Unique ID
          title: 'Operation Interrupted',
          body: '$desc was interrupted before completion. Please try again.',
        );
      }
      // Clear them so we don't notify again
      await taskPersistence.clearAllInterruptedTasks();
    }

    // 3. Check for forced updates
    final needsUpdate = await UpdateService.isUpdateRequired();
    if (needsUpdate) {
      return BootstrapResult.updateRequired;
    }

    // 4. Check for first launch (Onboarding)
    final hasSeenOnboarding = _prefs.getBool('has_seen_onboarding') ?? false;
    if (!hasSeenOnboarding) {
      return BootstrapResult.onboarding;
    }

    return BootstrapResult.home;
  }
}
*/
