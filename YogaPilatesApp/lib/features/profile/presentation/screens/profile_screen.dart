import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/navigation/app_router.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Личный кабинет (MVP): данные пользователя, тема, выход, вход в админку.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final session = ref.watch(currentSessionProvider);
    final roleAsync = ref.watch(roleControllerProvider);
    final isStaff = ref.watch(isStaffProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.person, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session?.user.email ?? 'Гость',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        roleAsync.when(
                          data: (role) => Text(
                            'Роль: ${role?.name ?? '—'}',
                            style: theme.textTheme.bodySmall,
                          ),
                          loading: () => const Text('Загрузка роли…'),
                          error: (_, __) => const Text('Роль недоступна'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.event_note_outlined),
            title: const Text('Мои занятия'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.myBookings),
          ),
          ListTile(
            leading: const Icon(Icons.card_membership_outlined),
            title: const Text('Мои абонементы'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppRoutes.myMemberships),
          ),
          const Divider(),
          if (isStaff)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Админ-панель'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.admin),
            ),
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('Тёмная тема'),
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) => ref
                  .read(themeModeProvider.notifier)
                  .set(v ? ThemeMode.dark : ThemeMode.light),
            ),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text('Выйти',
                style: TextStyle(color: theme.colorScheme.error)),
            onTap: () => ref.read(authActionsProvider).signOut(),
          ),
        ],
      ),
    );
  }
}
