import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../data/repositories/notification_repository_impl.dart';
import '../../../../domain/entities/app_notification.dart';
import '../../../../domain/entities/notification_settings.dart';
import '../../../../domain/repositories/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Список уведомлений текущего пользователя.
final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  return ref.watch(notificationRepositoryProvider).getMyNotifications();
});

/// Количество непрочитанных (для бейджа в навигации).
final unreadCountProvider = Provider<int>((ref) {
  final async = ref.watch(notificationsProvider);
  return async.valueOrNull?.where((n) => !n.isRead).length ?? 0;
});

/// Действия с уведомлениями (прочтение).
final notificationsControllerProvider =
    AsyncNotifierProvider<NotificationsController, void>(
        NotificationsController.new);

class NotificationsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> markRead(String id) async {
    await ref.read(notificationRepositoryProvider).markRead(id);
    ref.invalidate(notificationsProvider);
  }

  Future<void> markAllRead() async {
    await ref.read(notificationRepositoryProvider).markAllRead();
    ref.invalidate(notificationsProvider);
  }
}

/// Настройки уведомлений.
final notifySettingsProvider = FutureProvider<NotificationSettings>((ref) {
  return ref.watch(notificationRepositoryProvider).getSettings();
});

final notifySettingsControllerProvider =
    AsyncNotifierProvider<NotifySettingsController, void>(
        NotifySettingsController.new);

class NotifySettingsController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> update(NotificationSettings settings) async {
    await ref.read(notificationRepositoryProvider).updateSettings(settings);
    ref.invalidate(notifySettingsProvider);
  }
}
