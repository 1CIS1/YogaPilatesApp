import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/notification_settings.dart';
import '../providers/notification_providers.dart';

/// Экран настроек уведомлений (push, напоминания, новости, email).
class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notifySettingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки уведомлений')),
      body: settingsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(notifySettingsProvider),
            child: const Text('Повторить'),
          ),
        ),
        data: (s) {
          void save(NotificationSettings next) {
            ref.read(notifySettingsControllerProvider.notifier).update(next);
          }

          return ListView(
            children: [
              SwitchListTile(
                title: const Text('Push-уведомления'),
                subtitle: const Text('Все push-сообщения'),
                value: s.push,
                onChanged: (v) => save(s.copyWith(push: v)),
              ),
              SwitchListTile(
                title: const Text('Напоминания о занятиях'),
                subtitle: const Text('За 24 часа и за 2 часа до начала'),
                value: s.reminders,
                onChanged: (v) => save(s.copyWith(reminders: v)),
              ),
              SwitchListTile(
                title: const Text('Новости и акции'),
                value: s.news,
                onChanged: (v) => save(s.copyWith(news: v)),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Email-уведомления'),
                value: s.email,
                onChanged: (v) => save(s.copyWith(email: v)),
              ),
            ],
          );
        },
      ),
    );
  }
}
