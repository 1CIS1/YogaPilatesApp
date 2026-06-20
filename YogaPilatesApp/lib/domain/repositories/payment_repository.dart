import '../entities/enums.dart';
import '../entities/membership_plan.dart';

/// Черновик созданного платежа (id + итоговая сумма со скидками).
class PaymentDraft {
  const PaymentDraft({required this.paymentId, required this.amount});
  final String paymentId;
  final double amount;
}

/// Доступ к оплате (создание платежа, подтверждение, статус, тарифы).
abstract interface class PaymentRepository {
  /// Доступные тарифы абонементов.
  Future<List<MembershipPlan>> getMembershipPlans();

  /// Создать платёж. Возвращает id и итоговую сумму (после скидок).
  Future<PaymentDraft> createPayment({
    required PurchaseType type,
    required String relatedId,
    String? promoCode,
  });

  /// Подтвердить платёж (в тест-режиме — мгновенно; в бою — через webhook).
  Future<PaymentStatus> confirmPayment(String paymentId);

  /// Текущий статус платежа.
  Future<PaymentStatus> getPaymentStatus(String paymentId);

  /// Боевой режим: создать платёж у провайдера (Edge Function process-payment)
  /// и получить ссылку на страницу оплаты (confirmation_url).
  Future<String> createProviderPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
  });
}
