import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../data/repositories/payment_repository_impl.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/membership_plan.dart';
import '../../../../domain/repositories/payment_repository.dart';
import '../../../profile/presentation/providers/account_providers.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';

/// Аргументы экрана оформления покупки (передаются через GoRouter extra).
class CheckoutArgs {
  const CheckoutArgs({
    required this.type,
    required this.relatedId,
    required this.title,
    required this.subtitle,
    required this.price,
  });

  final PurchaseType type;
  final String relatedId;
  final String title;
  final String subtitle;
  final double price;
}

/// Репозиторий оплаты.
final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Доступные тарифы абонементов.
final membershipPlansProvider = FutureProvider<List<MembershipPlan>>((ref) {
  return ref.watch(paymentRepositoryProvider).getMembershipPlans();
});

/// Контроллер оформления покупки.
final checkoutControllerProvider =
    AsyncNotifierProvider<CheckoutController, void>(CheckoutController.new);

class CheckoutController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  PaymentRepository get _repo => ref.read(paymentRepositoryProvider);

  /// Создаёт платёж (status=pending) и возвращает черновик (id + сумма).
  Future<PaymentDraft> createDraft(CheckoutArgs args, {String? promoCode}) {
    return _repo.createPayment(
      type: args.type,
      relatedId: args.relatedId,
      promoCode: (promoCode != null && promoCode.trim().isNotEmpty)
          ? promoCode.trim()
          : null,
    );
  }

  /// ТЕСТ-режим: мгновенное подтверждение платежа.
  Future<PaymentStatus> confirmTest(String paymentId) async {
    final status = await _repo.confirmPayment(paymentId);
    if (status.isSuccess) _refresh();
    return status;
  }

  /// БОЕВОЙ режим: создать платёж у провайдера, получить ссылку оплаты.
  Future<String> startProviderPayment({
    required PaymentDraft draft,
    required String description,
    required String returnUrl,
  }) {
    return _repo.createProviderPayment(
      paymentId: draft.paymentId,
      amount: draft.amount,
      description: description,
      returnUrl: returnUrl,
    );
  }

  /// БОЕВОЙ режим: опрос статуса до успеха/отказа или таймаута.
  Future<PaymentStatus> pollStatus(
    String paymentId, {
    Duration timeout = const Duration(minutes: 2),
    Duration interval = const Duration(seconds: 2),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final s = await _repo.getPaymentStatus(paymentId);
      if (s == PaymentStatus.succeeded) {
        _refresh();
        return s;
      }
      if (s == PaymentStatus.failed) return s;
      await Future<void>.delayed(interval);
    }
    return PaymentStatus.pending;
  }

  void _refresh() {
    ref.invalidate(myMembershipsProvider);
    ref.invalidate(myScheduleProvider);
    ref.invalidate(scheduleForDayProvider);
  }
}
