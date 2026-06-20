import '../entities/app_notification.dart';
import '../entities/notification_settings.dart';

/// Доступ к уведомлениям и их настройкам.
abstract interface class NotificationRepository {
  Future<List<AppNotification>> getMyNotifications();
  Future<void> markRead(String notificationId);
  Future<void> markAllRead();

  /// Сохранить push-токен устройства (OneSignal subscription id / FCM token).
  Future<void> registerPushToken(String token, String platform);

  Future<NotificationSettings> getSettings();
  Future<void> updateSettings(NotificationSettings settings);
}
