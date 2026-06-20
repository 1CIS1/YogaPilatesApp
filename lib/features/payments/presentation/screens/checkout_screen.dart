import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_config.dart';
import '../../../../domain/entities/enums.dart';
import '../providers/payment_providers.dart';
import 'payment_webview_screen.dart';

/// Экран оформления покупки (абонемент или разовое занятие).
/// Тест-режим: оплата подтверждается мгновенно.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.args});

  final CheckoutArgs args;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _promoCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _promoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _busy = true);
    try {
      final ctrl = ref.read(checkoutControllerProvider.notifier);
      final draft = await ctrl.createDraft(widget.args, promoCode: _promoCtrl.text);

      PaymentStatus status;
      if (AppConfig.isProdPayments) {
        // Боевой режим: страница оплаты YooKassa + опрос статуса.
        final url = await ctrl.startProviderPayment(
          draft: draft,
          description: widget.args.title,
          returnUrl: AppConfig.paymentReturnUrl,
        );
        if (!mounted) return;
        await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => PaymentWebViewScreen(
              url: url,
              returnUrlPrefix: AppConfig.paymentReturnUrl,
            ),
          ),
        );
        if (!mounted) return;
        status = await ctrl.pollStatus(draft.paymentId);
      } else {
        // Тест-режим: мгновенное подтверждение.
        status = await ctrl.confirmTest(draft.paymentId);
      }

      if (!mounted) return;
      switch (status) {
        case PaymentStatus.succeeded:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оплата прошла успешно')),
          );
          context.pop(true);
        case PaymentStatus.pending:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Оплата не завершена')),
          );
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Платёж не прошёл')),
          );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ошибка оплаты: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = widget.args;

    return Scaffold(
      appBar: AppBar(title: const Text('Оформление покупки')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.title, style: theme.textTheme.titleLarge),
                  if (a.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(a.subtitle, style: theme.textTheme.bodyMedium),
                  ],
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Text('К оплате'),
                      const Spacer(),
                      Text('${a.price.toStringAsFixed(0)} ₽',
                          style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _promoCtrl,
            decoration: const InputDecoration(
              labelText: 'Промокод (необязательно)',
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 8),
          Text(
            'Итоговая сумма со скидками рассчитывается на сервере.',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _busy ? null : _pay,
            icon: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.lock_outline),
            label: Text(_busy ? 'Обработка…' : 'Оплатить'),
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppConfig.isProdPayments
                        ? 'Оплата картой через защищённую страницу YooKassa.'
                        : 'Тестовый режим оплаты: платёж подтверждается '
                            'мгновенно, реальные деньги не списываются.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
