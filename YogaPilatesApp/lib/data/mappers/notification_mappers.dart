import '../../domain/entities/app_notification.dart';

class NotificationMappers {
  NotificationMappers._();

  static AppNotification fromRow(Map<String, dynamic> r) {
    return AppNotification(
      id: r['id'] as String,
      title: r['title'] as String?,
      body: (r['body'] as String?) ?? '',
      data: (r['data'] as Map?)?.cast<String, dynamic>(),
      channel: (r['channel'] as String?) ?? 'in_app',
      isRead: (r['is_read'] as bool?) ?? false,
      createdAt: DateTime.parse(r['created_at'] as String).toLocal(),
    );
  }
}
