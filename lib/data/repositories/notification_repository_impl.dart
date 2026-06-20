import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/app_notification.dart';
import '../../domain/entities/notification_settings.dart';
import '../../domain/repositories/notification_repository.dart';
import '../mappers/notification_mappers.dart';

/// Реализация уведомлений поверх Supabase (RLS + RPC).
class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AppNotification>> getMyNotifications() async {
    // RLS возвращает только уведомления текущего пользователя.
    final res = await _client
        .from('notifications')
        .select('id, title, body, data, channel, is_read, created_at')
        .order('created_at', ascending: false)
        .limit(200);
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(NotificationMappers.fromRow).toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    await _client.rpc('mark_notification_read', params: {'p_id': notificationId});
  }

  @override
  Future<void> markAllRead() async {
    await _client.rpc('mark_all_notifications_read');
  }

  @override
  Future<void> registerPushToken(String token, String platform) async {
    await _client.rpc('register_push_token',
        params: {'p_token': token, 'p_platform': platform});
  }

  @override
  Future<NotificationSettings> getSettings() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return const NotificationSettings();
    final res = await _client
        .from('profiles')
        .select('notify_prefs')
        .eq('id', uid)
        .maybeSingle();
    return NotificationSettings.fromJson(
        res?['notify_prefs'] as Map<String, dynamic>?);
  }

  @override
  Future<void> updateSettings(NotificationSettings settings) async {
    await _client
        .rpc('update_notify_prefs', params: {'p_prefs': settings.toJson()});
  }
}
