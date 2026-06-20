import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/app_notification.dart';
import '../providers/notification_providers.dart';

/// Центр уведомлений: список с группировкой по дате и отметкой прочтения.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Уведомления'),
        actions: [
          IconButton(
            tooltip: 'Прочитать все',
            icon: const Icon(Icons.done_all),
            onPressed: () =>
                ref.read(notificationsControllerProvider.notifier).markAllRead(),
          ),
          IconButton(
            tooltip: 'Настройки',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push(AppRoutes.notificationSettings),
          ),
        ],
      ),
      body: notifsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить уведомления'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(notificationsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.notifications_off_outlined,
                    size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Center(child: Text('Пока нет уведомлений')),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(notificationsProvider);
              await ref.read(notificationsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: _buildGrouped(context, ref, items),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildGrouped(
      BuildContext context, WidgetRef ref, List<AppNotification> items) {
    final widgets = <Widget>[];
    String? currentHeader;
    for (final n in items) {
      final header = _dateHeader(n.createdAt);
      if (header != currentHeader) {
        currentHeader = header;
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(header,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: Colors.grey)),
        ));
      }
      widgets.add(_NotificationTile(
        item: n,
        onTap: () {
          if (!n.isRead) {
            ref.read(notificationsControllerProvider.notifier).markRead(n.id);
          }
        },
      ));
    }
    return widgets;
  }

  String _dateHeader(DateTime dt) {
    final now = DateTime.now();
    final d = DateTime(dt.year, dt.month, dt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(d).inDays;
    if (diff == 0) return 'Сегодня';
    if (diff == 1) return 'Вчера';
    return DateFormat('d MMMM yyyy', 'ru_RU').format(dt);
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AppNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.12),
        child: Icon(_iconFor(item.type), color: theme.colorScheme.primary),
      ),
      title: Text(item.title ?? 'Уведомление',
          style: TextStyle(
              fontWeight:
                  item.isRead ? FontWeight.normal : FontWeight.w600)),
      subtitle: Text(item.body),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(DateFormat('HH:mm').format(item.createdAt),
              style: theme.textTheme.bodySmall),
          if (!item.isRead) ...[
            const SizedBox(height: 6),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String? type) => switch (type) {
        'reminder_24h' || 'reminder_2h' => Icons.alarm,
        'class_cancelled' => Icons.event_busy,
        'birthday' => Icons.cake,
        'promotion' || 'news' => Icons.campaign,
        _ => Icons.notifications,
      };
}
