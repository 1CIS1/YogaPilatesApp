import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../../../../domain/entities/enums.dart';
import '../providers/admin_providers.dart';

/// Управление расписанием: список занятий на день, создание/правка/отмена.
class AdminClassesScreen extends ConsumerWidget {
  const AdminClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(adminSelectedDayProvider);
    final classesAsync = ref.watch(adminClassesProvider);
    final dayNotifier = ref.read(adminSelectedDayProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Расписание')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.adminClassForm),
        icon: const Icon(Icons.add),
        label: const Text('Занятие'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => dayNotifier
                      .select(day.subtract(const Duration(days: 1))),
                ),
                Text(DateFormat('EEEE, d MMMM', 'ru_RU').format(day),
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      dayNotifier.select(day.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: classesAsync.when(
              loading: () => const LoadingIndicator(),
              error: (e, _) => Center(
                child: FilledButton(
                  onPressed: () => ref.invalidate(adminClassesProvider),
                  child: const Text('Повторить'),
                ),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const Center(child: Text('На этот день занятий нет'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
                  itemCount: list.length,
                  itemBuilder: (_, i) =>
                      _ClassRow(item: list[i], ref: ref),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassRow extends StatelessWidget {
  const _ClassRow({required this.item, required this.ref});
  final AdminClass item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final timeFmt = DateFormat('HH:mm');
    final cancelled = item.status == ClassStatus.cancelled;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListTile(
        title: Text(item.classTypeName,
            style: TextStyle(
                decoration: cancelled ? TextDecoration.lineThrough : null)),
        subtitle: Text(
          '${timeFmt.format(item.startsAt)}–${timeFmt.format(item.endsAt)}'
          ' · ${item.bookedCount}/${item.capacity}'
          '${item.instructorName != null ? ' · ${item.instructorName}' : ''}'
          '${cancelled ? ' · отменено' : ''}',
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) => _onAction(context, v),
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Text('Редактировать')),
            const PopupMenuItem(
                value: 'waitlist', child: Text('Записи и очередь')),
            if (!cancelled)
              const PopupMenuItem(value: 'cancel', child: Text('Отменить')),
          ],
        ),
      ),
    );
  }

  Future<void> _onAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        context.push(AppRoutes.adminClassForm, extra: item);
      case 'waitlist':
        context.push(AppRoutes.adminClassWaitlist, extra: item);
      case 'cancel':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            content: const Text(
                'Отменить занятие? Записанным придёт уведомление.'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Нет')),
              FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Отменить занятие')),
            ],
          ),
        );
        if (ok == true) {
          await ref.read(adminControllerProvider.notifier).cancelClass(item.id);
        }
    }
  }
}
