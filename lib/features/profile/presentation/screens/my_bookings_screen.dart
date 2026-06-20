import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/my_schedule_item.dart';
import '../providers/account_providers.dart';

/// «Мои занятия»: предстоящие (записи + лист ожидания) и прошедшие.
class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(myScheduleProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои занятия'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Предстоящие'),
              Tab(text: 'Прошедшие'),
            ],
          ),
        ),
        body: scheduleAsync.when(
          loading: () => const LoadingIndicator(),
          error: (e, _) => _ErrorView(
            onRetry: () => ref.invalidate(myScheduleProvider),
          ),
          data: (items) {
            final upcoming = items.where((i) => i.isUpcoming).toList();
            final past = items
                .where((i) => i.kind == MyItemKind.booking && i.isPast)
                .toList()
              ..sort((a, b) => b.startsAt.compareTo(a.startsAt));

            return TabBarView(
              children: [
                _ScheduleList(
                  ref: ref,
                  items: upcoming,
                  emptyText: 'У вас нет предстоящих занятий',
                ),
                _ScheduleList(
                  ref: ref,
                  items: past,
                  emptyText: 'История занятий пуста',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScheduleList extends StatelessWidget {
  const _ScheduleList({
    required this.ref,
    required this.items,
    required this.emptyText,
  });

  final WidgetRef ref;
  final List<MyScheduleItem> items;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(myScheduleProvider);
        await ref.read(myScheduleProvider.future);
      },
      child: items.isEmpty
          ? ListView(
              children: [
                const SizedBox(height: 100),
                Icon(Icons.event_note,
                    size: 56, color: Theme.of(context).disabledColor),
                const SizedBox(height: 12),
                Center(child: Text(emptyText)),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (_, i) => _ScheduleItemCard(item: items[i]),
            ),
    );
  }
}

class _ScheduleItemCard extends ConsumerWidget {
  const _ScheduleItemCard({required this.item});

  final MyScheduleItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final fmt = DateFormat('EEE, d MMM · HH:mm', 'ru_RU');
    final busy = ref.watch(accountControllerProvider).isLoading;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(item.classTypeName,
                      style: theme.textTheme.titleMedium),
                ),
                _statusChip(theme),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${fmt.format(item.startsAt)}'
              '${item.instructorName != null ? ' · ${item.instructorName}' : ''}'
              '${item.hallName != null ? ' · ${item.hallName}' : ''}',
              style: theme.textTheme.bodySmall,
            ),
            if (item.isActiveBooking) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: busy ? null : () => _cancel(context, ref),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text('Отменить'),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
              ),
            ] else if (item.isWaitlist) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: busy ? null : () => _leaveWaitlist(context, ref),
                  icon: const Icon(Icons.logout, size: 18),
                  label: const Text('Выйти из очереди'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme) {
    final (String text, Color color) = switch (item) {
      _ when item.isWaitlist => (
          'В очереди: ${item.waitlistPosition}',
          const Color(0xFFF9AB00)
        ),
      _ when item.bookingStatus == BookingStatus.booked => (
          item.isPast ? 'Прошло' : 'Записан',
          theme.colorScheme.primary
        ),
      _ when item.bookingStatus == BookingStatus.attended => (
          'Посещено',
          const Color(0xFF34A853)
        ),
      _ when item.bookingStatus?.isCancelled ?? false => (
          'Отменено',
          const Color(0xFFD93025)
        ),
      _ => (item.bookingStatus?.label ?? '—', theme.disabledColor),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, 'Отменить запись на занятие?');
    if (!ok) return;
    try {
      await ref.read(accountControllerProvider.notifier).cancelBooking(item.itemId);
      if (context.mounted) _snack(context, 'Запись отменена');
    } catch (e) {
      if (context.mounted) _snack(context, 'Ошибка: $e');
    }
  }

  Future<void> _leaveWaitlist(BuildContext context, WidgetRef ref) async {
    final ok = await _confirm(context, 'Выйти из листа ожидания?');
    if (!ok) return;
    try {
      await ref
          .read(accountControllerProvider.notifier)
          .leaveWaitlist(item.scheduledClassId);
      if (context.mounted) _snack(context, 'Вы вышли из листа ожидания');
    } catch (e) {
      if (context.mounted) _snack(context, 'Ошибка: $e');
    }
  }
}

Future<bool> _confirm(BuildContext context, String text) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Нет')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, true), child: const Text('Да')),
      ],
    ),
  );
  return res ?? false;
}

void _snack(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Не удалось загрузить занятия'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
