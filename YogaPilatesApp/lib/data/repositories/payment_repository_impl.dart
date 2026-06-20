import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/enums.dart';
import '../../domain/entities/membership_plan.dart';
import '../../domain/repositories/payment_repository.dart';

/// Реализация оплаты поверх Supabase RPC.
/// В тест-режиме confirmPayment вызывается сразу после createPayment.
/// В бою подтверждение придёт из webhook YooKassa (Edge Function).
class PaymentRepositoryImpl implements PaymentRepository {
  PaymentRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MembershipPlan>> getMembershipPlans() async {
    final res = await _client
        .from('membership_plans')
        .select('id, name, kind, classes_count, duration_days, price')
        .eq('is_active', true)
        .order('price');
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows
        .map((r) => MembershipPlan(
              id: r['id'] as String,
              name: (r['name'] as String?) ?? '',
              kind: MembershipKind.fromDb(r['kind'] as String?),
              price: (r['price'] as num?)?.toDouble() ?? 0,
              classesCount: (r['classes_count'] as num?)?.toInt(),
              durationDays: (r['duration_days'] as num?)?.toInt(),
            ))
        .toList();
  }

  @override
  Future<PaymentDraft> createPayment({
    required PurchaseType type,
    required String relatedId,
    String? promoCode,
  }) async {
    final res = await _client.rpc('create_payment', params: {
      'p_purchase_type': type.dbValue,
      'p_related_id': relatedId,
      'p_promo_code': promoCode,
    });
    final row = (res as List).cast<Map<String, dynamic>>().first;
    return PaymentDraft(
      paymentId: row['payment_id'] as String,
      amount: (row['amount'] as num).toDouble(),
    );
  }

  @override
  Future<PaymentStatus> confirmPayment(String paymentId) async {
    final res = await _client
        .rpc('confirm_payment', params: {'p_payment_id': paymentId});
    final code = res as String?;
    // confirm_payment возвращает 'succeeded' | 'already_succeeded'.
    if (code == 'succeeded' || code == 'already_succeeded') {
      return PaymentStatus.succeeded;
    }
    return PaymentStatus.pending;
  }

  @override
  Future<PaymentStatus> getPaymentStatus(String paymentId) async {
    final res = await _client
        .rpc('get_payment_status', params: {'p_payment_id': paymentId});
    return PaymentStatus.fromDb(res as String?);
  }

  @override
  Future<String> createProviderPayment({
    required String paymentId,
    required double amount,
    required String description,
    required String returnUrl,
  }) async {
    final res = await _client.functions.invoke('process-payment', body: {
      'payment_id': paymentId,
      'amount': amount,
      'description': description,
      'return_url': returnUrl,
    });
    final data = res.data;
    final url = (data is Map) ? data['confirmation_url'] as String? : null;
    if (url == null || url.isEmpty) {
      throw Exception('Не удалось получить ссылку оплаты от провайдера');
    }
    return url;
  }
}
