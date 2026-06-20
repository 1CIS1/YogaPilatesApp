import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/membership.dart';
import '../providers/account_providers.dart';

/// «Мои абонементы»: активные и история.
class MyMembershipsScreen extends ConsumerWidget {
  const MyMembershipsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membershipsAsync = ref.watch(myMembershipsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Мои абонементы')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.membershipPlans),
        icon: const Icon(Icons.add_card),
        label: const Text('Купить абонемент'),
      ),
      body: membershipsAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить абонементы'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(myMembershipsProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('У вас нет активных абонементов'));
          }
          final active = items.where((m) => m.status.isActive).toList();
          final history = items.where((m) => !m.status.isActive).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myMembershipsProvider);
              await ref.read(myMembershipsProvider.future);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
              children: [
                if (active.isNotEmpty) ...[
                  _sectionTitle(context, 'Активные'),
                  for (final m in active) _MembershipCard(membership: m),
                ],
                if (history.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionTitle(context, 'История'),
                  for (final m in history) _MembershipCard(membership: m),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _MembershipCard extends StatelessWidget {
  const _MembershipCard({required this.membership});

  final Membership membership;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final m = membership;
    final progress = m.usageProgress;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(m.planName, style: theme.textTheme.titleMedium)),
                _statusChip(theme),
              ],
            ),
            const SizedBox(height: 4),
            Text(m.kind.label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 12),
            if (m.kind.isCountBased && m.classesTotal != null) ...[
              Text('Осталось ${m.classesLeft ?? 0} из ${m.classesTotal}',
                  style: theme.textTheme.bodyMedium),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress == null ? null : (1 - progress),
                  minHeight: 8,
                ),
              ),
            ] else
              Text('Безлимитное посещение',
                  style: theme.textTheme.bodyMedium),
            if (m.validUntil != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.event_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Действует до ${DateFormat('dd.MM.yyyy').format(m.validUntil!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusChip(ThemeData theme) {
    final color =
        membership.status.isActive ? const Color(0xFF34A853) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(membership.status.label,
          style: theme.textTheme.labelMedium?.copyWith(color: color)),
    );
  }
}
