/// Уведомление в центре уведомлений (имя AppNotification, чтобы не путать
/// с Flutter Notification).
class AppNotification {
  const AppNotification({
    required this.id,
    required this.body,
    required this.channel,
    required this.isRead,
    required this.createdAt,
    this.title,
    this.data,
  });

  final String id;
  final String? title;
  final String body;
  final Map<String, dynamic>? data;
  final String channel;
  final bool isRead;
  final DateTime createdAt;

  /// Тип события (reminder_24h, class_cancelled, birthday и т.д.).
  String? get type => data?['type'] as String?;
}
