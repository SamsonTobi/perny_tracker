// A simple model class to store notification data
// This can be expanded later to include more fields or processing logic

class NotificationEventModel {
  final String? packageName;
  final String? title;
  final String? content;
  final DateTime timestamp;
  final bool? hasRemoved;
  final bool? canReply;
  final List<int>? appIcon;
  final List<int>? largeIcon;

  NotificationEventModel({
    this.packageName,
    this.title,
    this.content,
    required this.timestamp,
    this.hasRemoved,
    this.canReply,
    this.appIcon,
    this.largeIcon,
  });

  // Factory constructor to create a model from a ServiceNotificationEvent
  factory NotificationEventModel.fromEvent(dynamic event) {
    return NotificationEventModel(
      packageName: event.packageName,
      title: event.title,
      content: event.content,
      timestamp: DateTime.now(),
      hasRemoved: event.hasRemoved,
      canReply: event.canReply,
      appIcon: event.appIcon,
      largeIcon: event.largeIcon,
    );
  }

  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'title': title,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'hasRemoved': hasRemoved,
      'canReply': canReply,
      // Note: Binary data like icons would need special handling for storage
    };
  }

  // Create from a map (for storage retrieval)
  factory NotificationEventModel.fromMap(Map<String, dynamic> map) {
    return NotificationEventModel(
      packageName: map['packageName'],
      title: map['title'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      hasRemoved: map['hasRemoved'],
      canReply: map['canReply'],
      // Note: Binary data would need to be retrieved separately
    );
  }

  @override
  String toString() {
    return 'NotificationEvent: $packageName - $title';
  }
}

