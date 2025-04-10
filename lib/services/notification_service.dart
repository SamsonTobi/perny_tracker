// lib/services/notification_service.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:notification_listener_service/notification_listener_service.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';
import '../models/notification_event_model.dart';
import '../repositories/expense_repository.dart';

typedef NotificationCallback = void Function(ServiceNotificationEvent event);

class NotificationService {
  static StreamSubscription<ServiceNotificationEvent>? _subscription;
  static NotificationCallback? _callback;
  static final _expenseRepository = ExpenseRepository();

  // Initialize notification service
  static Future<void> initialize() async {
    try {
      // Check if permission is already granted
      final bool isGranted = await isPermissionGranted();
      AppLogger.log("Notification permission status on init: $isGranted");
    } catch (e) {
      AppLogger.error("Error initializing notification service: $e");
    }
  }

  // Request notification listener permission
  static Future<bool> requestPermission() async {
    try {
      final bool result = await NotificationListenerService.requestPermission();
      AppLogger.log("Permission request result: $result");
      return result;
    } catch (e) {
      AppLogger.error("Error requesting permission: $e");
      return false;
    }
  }

  // Check if permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      final bool result =
          await NotificationListenerService.isPermissionGranted();
      return result;
    } catch (e) {
      AppLogger.error("Error checking permission: $e");
      return false;
    }
  }

  // Start listening for notifications in background mode
  static void startListeningInBackground(NotificationCallback? callback) {
    try {
      // Cancel existing subscription if any
      _subscription?.cancel();

      // Store callback for later use (may be null if app is closed)
      _callback = callback;

      // Start listening for notifications
      _subscription = NotificationListenerService.notificationsStream.listen(
        (event) async {
          debugPrint("Background notification received: ${event.title}");

          if (event.hasRemoved == false && event.packageName != null) {
            debugPrint("New notification received: ${event.title}");

            // Create model from event
            final model = NotificationEventModel.fromEvent(event);

            // Process notification through expense repository
            try {
              final processed =
                  await _expenseRepository.createExpenseFromNotification(model);
              if (processed) {
                debugPrint(
                    "Bank notification processed as expense: ${event.title}");
              }
            } catch (e) {
              AppLogger.error("Error processing notification as expense: $e");
            }

            // Try to call the callback, but it may fail if app is closed
            try {
              if (_callback != null) {
                _callback!(event);
              }
            } catch (e) {
              // This is expected to fail when app is closed
              AppLogger.log("Ignoring callback error - app likely closed");
            }
          } else {
            debugPrint(
                "Ignoring notification update or removal: ${event.title}");
          }
        },
        onError: (error) {
          AppLogger.error("Error in background notification stream: $error");
        },
      );

      debugPrint("Background notification listener started");
    } catch (e) {
      AppLogger.error("Error starting background notification listener: $e");
    }
  }

  // Stop listening for notifications
  static void stopListening() {
    try {
      _subscription?.cancel();
      _subscription = null;
      _callback = null;
      AppLogger.log("Notification listener stopped");
    } catch (e) {
      AppLogger.error("Error stopping notification listener: $e");
    }
  }
}
