import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/notifications/presentation/providers/notification_providers.dart';
import 'app_router.dart';

/// Каркас клиентской части с нижней навигацией.
/// Текущая вкладка определяется по текущему пути.
class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({
    super.key,
    required this.child,
    required this.location,
  });

  final Widget child;
  final String location;

  static const _tabs = <_NavTab>[
    _NavTab(AppRoutes.schedule, Icons.calendar_month_outlined,
        Icons.calendar_month, 'Расписание'),
    _NavTab(AppRoutes.notifications, Icons.notifications_outlined,
        Icons.notifications, 'Уведомления'),
    _NavTab(AppRoutes.profile, Icons.person_outline, Icons.person, 'Профиль'),
  ];

  int get _currentIndex {
    final i = _tabs.indexWhere((t) => location.startsWith(t.path));
    return i < 0 ? 0 : i;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: t.path == AppRoutes.notifications && unread > 0
                  ? Badge.count(count: unread, child: Icon(t.icon))
                  : Icon(t.icon),
              selectedIcon: t.path == AppRoutes.notifications && unread > 0
                  ? Badge.count(count: unread, child: Icon(t.activeIcon))
                  : Icon(t.activeIcon),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _NavTab {
  const _NavTab(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
