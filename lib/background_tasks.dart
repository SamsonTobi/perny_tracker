import 'package:workmanager/workmanager.dart';
import 'package:flutter/foundation.dart'; // For debugPrint
import 'services/background_service.dart'; // Import your service manager
import 'utils/logger.dart'; // Assuming you have a logger

// A unique name for the periodic background task
const periodicTaskName = "checkExpenseServicePeriodic";
// A unique name for the task triggered on boot or by other means
const oneOffTaskName = "ensureExpenseServiceRunning";

// This function needs to be top-level or static
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    AppLogger.log("Native WorkManager task: $task"); // Log task execution

    switch (task) {
      case periodicTaskName:
      case oneOffTaskName: // Handle both tasks similarly
        try {
          // Check if the background service is already running
          final isRunning = await BackgroundServiceManager.isServiceRunning();
          AppLogger.log("WorkManager check: Service running? $isRunning");

          if (!isRunning) {
            AppLogger.log(
                "WorkManager: Service not running, attempting to start...");
            // Ensure the service is initialized before starting
            // Note: initializeBackgroundService might need adjustments
            // if it relies on Flutter context not available here.
            // Consider making initialization idempotent or splitting it.
            // For now, we assume startService handles necessary setup.
            await BackgroundServiceManager.startService();
            AppLogger.log("WorkManager: Service start command issued.");
          }
        } catch (err) {
          AppLogger.error("WorkManager task error: $err");
          return Future.value(false); // Indicate failure
        }
        break;
      default:
        AppLogger.log("WorkManager: Unknown task $task");
        return Future.value(false); // Indicate failure for unknown tasks
    }

    // Indicate success
    return Future.value(true);
  });
}

// Helper class to manage WorkManager tasks
class BackgroundTaskManager {
  static Future<void> initializeAndScheduleWork() async {
    try {
      // Initialize WorkManager
      // The callbackDispatcher needs to be defined at the top level or as a static method.
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: kDebugMode, // Set to true for debugging WorkManager
      );
      AppLogger.log("WorkManager initialized.");

      // Register a periodic task to check the service
      // Runs approximately every 15 minutes (minimum allowed interval)
      await Workmanager().registerPeriodicTask(
        "1", // Unique ID for the task
        periodicTaskName,
        frequency: const Duration(minutes: 15),
        // Constraints can be added, e.g., require network
        // constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy:
            ExistingWorkPolicy.keep, // Keep existing task if already scheduled
      );
      AppLogger.log("WorkManager periodic task registered.");
    } catch (err) {
      AppLogger.error("Error initializing or scheduling WorkManager: $err");
    }
  }

  // Optional: Schedule a one-off task for immediate check/start if needed
  static Future<void> scheduleOneOffTask() async {
    try {
      await Workmanager().registerOneOffTask(
        "2", // Unique ID
        oneOffTaskName,
        initialDelay: const Duration(seconds: 10), // Small delay
        existingWorkPolicy: ExistingWorkPolicy.replace, // Replace if exists
      );
      AppLogger.log("WorkManager one-off task scheduled.");
    } catch (err) {
      AppLogger.error("Error scheduling WorkManager one-off task: $err");
    }
  }
}
