import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';

/// Карточка клиента: данные, бонусы, абонементы, последние посещения.
class AdminClientProfileScreen extends ConsumerWidget {
  const AdminClientProfileScreen({super.key, required this.clientId});

  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(adminClientDetailsProvider(clientId));
    final membershipsAsync = ref.watch(adminClientMembershipsProvider(clientId));
    final bookingsAsync = ref.watch(adminClientBookingsProvider(clientId));

    return Scaffold(
      appBar: AppBar(title: const Text('Карточка клиента')),
      body: detailsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(adminClientDetailsProvider(clientId)),
            child: const Text('Повторить'),
          ),
        ),
        data: (d) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _profileCard(context, d),
            const SizedBox(height: 16),
            _bonusCard(context, ref, d),
            const SizedBox(height: 16),
            Text('Абонементы', style: Theme.of(context).textTheme.titleMedium),
            membershipsAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
              error: (_, __) => const Text('—'),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8), child: Text('Нет абонементов'))
                  : Column(children: [for (final m in list) _membershipTile(m)]),
            ),
            const SizedBox(height: 16),
            Text('Последние занятия',
                style: Theme.of(context).textTheme.titleMedium),
            bookingsAsync.when(
              loading: () => const Padding(
                  padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
              error: (_, __) => const Text('—'),
              data: (list) => list.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(8), child: Text('Нет посещений'))
                  : Column(children: [for (final b in list) _bookingTile(b)]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileCard(BuildContext context, AdminClientDetails d) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(d.fullName ?? 'Без имени', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            if (d.phone != null) Text('Телефон: ${d.phone}'),
            if (d.email != null) Text('Email: ${d.email}'),
            if (d.birthDate != null)
              Text('Дата рождения: '
                  '${DateFormat('dd.MM.yyyy').format(d.birthDate!)}'),
            Text('Статус: ${d.tier}'),
            if (d.isBlocked)
              const Text('Заблокирован', style: TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _bonusCard(BuildContext context, WidgetRef ref, AdminClientDetails d) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.stars, color: theme.colorScheme.secondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Бонусы: ${d.bonusBalance}',
                  style: theme.textTheme.titleMedium),
            ),
            OutlinedButton(
              onPressed: () => _adjustDialog(context, ref),
              child: const Text('Изменить'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _membershipTile(AdminMembershipRow m) {
    final left = m.classesTotal != null
        ? '${m.classesLeft ?? 0}/${m.classesTotal}'
        : 'безлимит';
    return ListTile(
      dense: true,
      leading: const Icon(Icons.card_membership),
      title: Text(m.planName),
      subtitle: Text('Осталось: $left · ${m.status.label}'),
      trailing: m.validUntil != null
          ? Text('до ${DateFormat('dd.MM.yy').format(m.validUntil!)}')
          : null,
    );
  }

  Widget _bookingTile(AdminBookingRow b) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.event_available),
      title: Text(b.className),
      subtitle: Text(DateFormat('dd.MM.yyyy HH:mm').format(b.startsAt)),
      trailing: Text(b.status.label),
    );
  }

  Future<void> _adjustDialog(BuildContext context, WidgetRef ref) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Изменить бонусы'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                  labelText: 'Сумма (например, 100 или -50)'),
            ),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(labelText: 'Причина'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Отмена')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Применить')),
        ],
      ),
    );
    if (result == true) {
      final amount = int.tryParse(amountCtrl.text.trim());
      if (amount == null || amount == 0) return;
      try {
        await ref.read(adminControllerProvider.notifier).adjustBonuses(
              clientId,
              amount,
              reasonCtrl.text.trim().isEmpty
                  ? 'Корректировка администратором'
                  : reasonCtrl.text.trim(),
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Бонусы обновлены')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }
}
