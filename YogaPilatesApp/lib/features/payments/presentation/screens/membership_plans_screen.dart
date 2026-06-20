import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/enums.dart';
import '../providers/payment_providers.dart';

/// Список тарифов абонементов для покупки.
class MembershipPlansScreen extends ConsumerWidget {
  const MembershipPlansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(membershipPlansProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Купить абонемент')),
      body: plansAsync.when(
        loading: () => const LoadingIndicator(),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Не удалось загрузить тарифы'),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => ref.invalidate(membershipPlansProvider),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ),
        data: (plans) {
          if (plans.isEmpty) {
            return const Center(child: Text('Тарифы пока не добавлены'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: plans.length,
            itemBuilder: (_, i) {
              final p = plans[i];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(p.summary, style: theme.textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('${p.price.toStringAsFixed(0)} ₽',
                              style: theme.textTheme.titleLarge?.copyWith(
                                  color: theme.colorScheme.primary)),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => context.push(
                              AppRoutes.checkout,
                              extra: CheckoutArgs(
                                type: PurchaseType.membership,
                                relatedId: p.id,
                                title: p.name,
                                subtitle: p.summary,
                                price: p.price,
                              ),
                            ),
                            child: const Text('Купить'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
