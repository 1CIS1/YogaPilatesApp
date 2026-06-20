import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/app_config.dart';

/// Обёртка над OneSignal. Все вызовы безопасны: если App ID не задан или SDK
/// недоступен — методы тихо ничего не делают (приложение работает без push).
class OneSignalService {
  OneSignalService._();

  static Future<void> init() async {
    if (!AppConfig.isOneSignalConfigured) return;
    try {
      OneSignal.initialize(AppConfig.oneSignalAppId);
      await OneSignal.Notifications.requestPermission(true);
    } catch (_) {
      // SDK недоступен в этой среде — игнорируем.
    }
  }

  /// Привязать push-подписку к пользователю (external_user_id = Supabase uid).
  static Future<void> login(String userId) async {
    if (!AppConfig.isOneSignalConfigured) return;
    try {
      OneSignal.login(userId);
    } catch (_) {}
  }

  static Future<void> logout() async {
    if (!AppConfig.isOneSignalConfigured) return;
    try {
      OneSignal.logout();
    } catch (_) {}
  }

  /// Id push-подписки (для сохранения в push_tokens при необходимости).
  static String? get subscriptionId {
    try {
      return OneSignal.User.pushSubscription.id;
    } catch (_) {
      return null;
    }
  }
}
