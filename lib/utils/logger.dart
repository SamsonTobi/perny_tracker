import 'dart:developer' as developer;

class AppLogger {
  static void log(String message) {
    developer.log(message, name: 'NotificationListener');
    print('📱 INFO: $message');
  }

  static void error(String message) {
    developer.log(message, name: 'NotificationListener', error: true);
    print('❌ ERROR: $message');
  }

  static void debug(String message) {
    developer.log(message, name: 'NotificationListener');
    print('🔍 DEBUG: $message');
  }
}