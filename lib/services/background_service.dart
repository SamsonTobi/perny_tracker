import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/logger.dart';
import 'notification_service.dart';
import '../models/notification_event_model.dart';
import '../repositories/expense_repository.dart';

// Background service initialization
Future<void> initializeBackgroundService() async {
  final service = FlutterBackgroundService();

  // Configure notification channel for foreground service
  const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'expense_tracker_channel',
    'Expense Tracker Service',
    description: 'This channel is used for the expense tracker service',
    importance: Importance.high,
    sound: null,
    enableVibration: false,
  );

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  if (Platform.isAndroid) {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // Initialize the background service
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: 'expense_tracker_channel',
      initialNotificationTitle: 'Expense Tracker',
      initialNotificationContent: 'Monitoring bank notifications',
      foregroundServiceNotificationId: 888,
    ),
    iosConfiguration: IosConfiguration(
      autoStart: false,
      onForeground: onStart,
      onBackground: onIosBackground,
    ),
  );
}

// iOS background handler
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

// Main background service handler
@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  AppLogger.log("Background service started");

  // Repository instance for processing expenses
  final expenseRepository = ExpenseRepository();

  // For Android, we need to show a persistent notification
  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    AppLogger.log("Stopping background service");
    service.stopSelf();
  });

  // Initialize notification listener
  try {
    await NotificationService.initialize();
    final bool isGranted = await NotificationService.isPermissionGranted();

    if (isGranted) {
      AppLogger.log("Permission granted, starting notification listener");

      // Start background listening
      NotificationService.startListeningInBackground((event) {
        if (event.hasRemoved == false) {
          AppLogger.log(
              "New notification received in background: ${event.title}");

          // Convert to model format for repository processing
          final model = NotificationEventModel.fromEvent(event);

          // Use repository's method to check if it's a bank notification
          if (expenseRepository.isBankNotification(model)) {
            AppLogger.log("""
BANK NOTIFICATION DETECTED IN BACKGROUND SERVICE:
packageName: ${event.packageName}
title: ${event.title}
content: ${event.content}
timestamp: ${DateTime.now().toIso8601String()}
hasRemoved: ${event.hasRemoved}
canReply: ${event.canReply}
------------------------------
""");

            // Process the notification as an expense
            expenseRepository.createExpenseFromNotification(model);

            // Update the foreground notification with latest transaction
            if (service is AndroidServiceInstance) {
              final amount = expenseRepository.extractAmount(event.content);
              final bankName = event.packageName != null
                  ? _getBankName(event.packageName!)
                  : 'Unknown Bank';

              service.setForegroundNotificationInfo(
                title: "New Expense Tracked",
                content: "₦$amount from $bankName",
              );
            }
          }
        } else {
          AppLogger.log(
              "Ignoring notification update or removal: ${event.title}");
        }
      });

      // Set initial foreground notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Expense Tracker Running",
          content: "Monitoring bank notifications",
        );
      }
    } else {
      AppLogger.error("Notification permission not granted");
    }
  } catch (e) {
    AppLogger.error("Error in background service: $e");
  }

  // Add a heartbeat to keep the service alive
  Timer.periodic(const Duration(minutes: 5), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // This is just to keep the service alive
      }
    }

    // Send heartbeat to confirm service is running
    service.invoke('update', {
      'isRunning': true,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });
}

// Helper function to get bank name from package name
String _getBankName(String packageName) {
  switch (packageName) {
    case 'com.kudabank.app':
      return 'Kuda Bank';
    case 'team.opay.pay':
      return 'OPay';
    case 'com.moniepoint.personal':
      return 'Moniepoint';
    default:
      return 'Unknown Bank';
  }
}

// Background service manager class
class BackgroundServiceManager {
  static Future<bool> isServiceRunning() async {
    final service = FlutterBackgroundService();
    return await service.isRunning();
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    await service.startService();
  }

  static Future<void> stopService() {
    final service = FlutterBackgroundService();
    service.invoke('stopService'); // No await since invoke() returns void
    return Future
        .value(); // Return an empty  // No await since invoke() returns void
  }
}
