import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

/// Главный экран админ-панели: статистика + навигация по разделам.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminDashboardStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Админ-панель'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(adminDashboardStatsProvider);
          await ref.read(adminDashboardStatsProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            statsAsync.when(
              loading: () => const SizedBox(
                  height: 120, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => const Text('Не удалось загрузить статистику'),
              data: (s) => _StatsGrid(stats: s),
            ),
            const SizedBox(height: 24),
            Text('Разделы', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _navTile(context, Icons.calendar_month, 'Управление расписанием',
                AppRoutes.adminClasses),
            _navTile(context, Icons.people_outline, 'Клиенты',
                AppRoutes.adminClients),
            _navTile(context, Icons.bar_chart, 'Отчёты', AppRoutes.adminReports),
          ],
        ),
      ),
    );
  }

  Widget _navTile(
      BuildContext context, IconData icon, String title, String route) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Занятий сегодня', '${stats.todayClasses}', Icons.event),
      ('Записей сегодня', '${stats.todayBookings}', Icons.how_to_reg),
      ('Выручка сегодня', '${stats.todayRevenue.toStringAsFixed(0)} ₽',
          Icons.payments),
      ('Всего клиентов', '${stats.totalClients}', Icons.people),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        for (final it in items)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(it.$3, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text(it.$2,
                      style: Theme.of(context).textTheme.headlineSmall),
                  Text(it.$1, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
