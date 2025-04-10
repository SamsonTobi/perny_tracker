// notification_storage.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'lib/models/notification_event_model.dart';

class NotificationStorage {
  static const String _storageKey = 'stored_notifications';

  // Save a notification to storage
  static Future<void> saveNotification(
      NotificationEventModel notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing notifications
      List<NotificationEventModel> notifications = await getNotifications();

      // Add new notification
      notifications.add(notification);

      // Limit storage to prevent excessive memory usage
      if (notifications.length > 100) {
        // Keep only the 100 most recent notifications
        notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifications = notifications.take(100).toList();
      }

      // Convert to JSON and save
      final List<String> jsonList = notifications
          .map((notification) => jsonEncode(notification.toMap()))
          .toList();

      await prefs.setStringList(_storageKey, jsonList);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  // Get all stored notifications
  static Future<List<NotificationEventModel>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? jsonList = prefs.getStringList(_storageKey);

      if (jsonList == null || jsonList.isEmpty) {
        return [];
      }

      return jsonList
          .map((json) => NotificationEventModel.fromMap(jsonDecode(json)))
          .toList();
    } catch (e) {
      print('Error retrieving notifications: $e');
      return [];
    }
  }

  // Clear all notifications
  static Future<void> clearNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing notifications: $e');
    }
  }
}
