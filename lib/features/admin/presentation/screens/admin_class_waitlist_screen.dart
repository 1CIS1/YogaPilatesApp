import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

/// Управление записями и листом ожидания конкретного занятия.
class AdminClassWaitlistScreen extends ConsumerWidget {
  const AdminClassWaitlistScreen({super.key, required this.classItem});

  final AdminClass classItem;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(adminClassBookingsProvider(classItem.id));
    final waitlistAsync = ref.watch(adminClassWaitlistProvider(classItem.id));
    final theme = Theme.of(context);
    final timeFmt = DateFormat('dd.MM HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(classItem.classTypeName)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${timeFmt.format(classItem.startsAt)} · '
              'мест ${classItem.bookedCount}/${classItem.capacity}'),
          const SizedBox(height: 16),
          Text('Записаны', style: theme.textTheme.titleMedium),
          bookingsAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
            error: (_, __) => const Text('—'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8), child: Text('Никто не записан'))
                : Column(
                    children: [
                      for (final b in list)
                        ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(b.clientName ?? b.clientEmail ?? '—'),
                          trailing: TextButton(
                            onPressed: () => _cancel(context, ref, b.bookingId),
                            child: const Text('Снять'),
                          ),
                        ),
                    ],
                  ),
          ),
          const Divider(height: 32),
          Text('Лист ожидания', style: theme.textTheme.titleMedium),
          waitlistAsync.when(
            loading: () => const Padding(
                padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
            error: (_, __) => const Text('—'),
            data: (list) => list.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text('Лист ожидания пуст'))
                : Column(
                    children: [
                      for (final w in list)
                        ListTile(
                          leading: CircleAvatar(child: Text('${w.position}')),
                          title: Text(w.clientName ?? '—'),
                          trailing: FilledButton(
                            onPressed: () =>
                                _promote(context, ref, w.waitlistId),
                            child: const Text('В запись'),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(
      BuildContext context, WidgetRef ref, String bookingId) async {
    try {
      await ref
          .read(adminControllerProvider.notifier)
          .cancelBooking(bookingId, classItem.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Запись снята')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _promote(
      BuildContext context, WidgetRef ref, String waitlistId) async {
    try {
      final r = await ref
          .read(adminControllerProvider.notifier)
          .promoteWaitlist(waitlistId, classItem.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r == 'full'
              ? 'Нет свободных мест'
              : 'Клиент перенесён в запись'),
        ));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }
}
