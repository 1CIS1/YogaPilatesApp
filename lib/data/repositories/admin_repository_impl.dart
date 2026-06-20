import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/admin_entities.dart';
import '../../domain/entities/enums.dart';
import '../../domain/repositories/admin_repository.dart';

/// Реализация админ-репозитория поверх Supabase RPC.
class AdminRepositoryImpl implements AdminRepository {
  AdminRepositoryImpl(this._client);

  final SupabaseClient _client;

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static double _toD(Object? v) => v == null ? 0 : (v as num).toDouble();

  List<Map<String, dynamic>> _rows(Object? res) =>
      (res as List).cast<Map<String, dynamic>>();

  // ---- Расписание ----
  @override
  Future<List<AdminClass>> getClasses(DateTime from, DateTime to) async {
    final res = await _client.rpc('admin_get_classes', params: {
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
    });
    return _rows(res)
        .map((r) => AdminClass(
              id: r['id'] as String,
              classTypeId: r['class_type_id'] as String,
              classTypeName: (r['class_type_name'] as String?) ?? '',
              instructorId: r['instructor_id'] as String?,
              instructorName: r['instructor_name'] as String?,
              hallId: r['hall_id'] as String?,
              hallName: r['hall_name'] as String?,
              startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
              endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
              capacity: (r['capacity'] as num).toInt(),
              bookedCount: (r['booked_count'] as num?)?.toInt() ?? 0,
              difficulty: DifficultyLevel.fromDb(r['difficulty'] as String?),
              status: ClassStatus.fromDb(r['status'] as String?),
              price: _toD(r['price']),
            ))
        .toList();
  }

  @override
  Future<String> createClass({
    required String classTypeId,
    String? instructorId,
    String? hallId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    required DifficultyLevel difficulty,
    required double price,
  }) async {
    final res = await _client.rpc('admin_create_class', params: {
      'p_class_type_id': classTypeId,
      'p_instructor_id': instructorId,
      'p_hall_id': hallId,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_ends_at': endsAt.toUtc().toIso8601String(),
      'p_capacity': capacity,
      'p_difficulty': difficulty.dbValue,
      'p_price': price,
    });
    return res as String;
  }

  @override
  Future<void> updateClass({
    required String id,
    required String classTypeId,
    String? instructorId,
    String? hallId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    required DifficultyLevel difficulty,
    required double price,
  }) async {
    await _client.rpc('admin_update_class', params: {
      'p_id': id,
      'p_class_type_id': classTypeId,
      'p_instructor_id': instructorId,
      'p_hall_id': hallId,
      'p_starts_at': startsAt.toUtc().toIso8601String(),
      'p_ends_at': endsAt.toUtc().toIso8601String(),
      'p_capacity': capacity,
      'p_difficulty': difficulty.dbValue,
      'p_price': price,
    });
  }

  @override
  Future<void> cancelClass(String id) async {
    await _client.rpc('admin_cancel_class', params: {'p_id': id});
  }

  @override
  Future<List<AdminHall>> getHalls() async {
    final res = await _client.rpc('admin_get_halls');
    return _rows(res)
        .map((r) => AdminHall(
              id: r['id'] as String,
              name: (r['name'] as String?) ?? '',
              capacity: (r['capacity'] as num?)?.toInt() ?? 0,
            ))
        .toList();
  }

  // ---- Клиенты ----
  @override
  Future<List<AdminClient>> getClients(String? search) async {
    final res =
        await _client.rpc('admin_get_clients', params: {'p_search': search});
    return _rows(res)
        .map((r) => AdminClient(
              id: r['id'] as String,
              fullName: r['full_name'] as String?,
              phone: r['phone'] as String?,
              email: r['email'] as String?,
              tier: (r['tier'] as String?) ?? 'new',
              isBlocked: (r['is_blocked'] as bool?) ?? false,
            ))
        .toList();
  }

  @override
  Future<AdminClientDetails> getClientDetails(String clientId) async {
    final res = await _client
        .rpc('admin_get_client', params: {'p_client_id': clientId});
    final r = _rows(res).first;
    return AdminClientDetails(
      id: r['id'] as String,
      fullName: r['full_name'] as String?,
      phone: r['phone'] as String?,
      email: r['email'] as String?,
      birthDate: r['birth_date'] == null
          ? null
          : DateTime.parse(r['birth_date'] as String),
      tier: (r['tier'] as String?) ?? 'new',
      isBlocked: (r['is_blocked'] as bool?) ?? false,
      bonusBalance: (r['bonus_balance'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  Future<List<AdminMembershipRow>> getClientMemberships(String clientId) async {
    final res = await _client
        .rpc('admin_get_client_memberships', params: {'p_client_id': clientId});
    return _rows(res)
        .map((r) => AdminMembershipRow(
              planName: (r['plan_name'] as String?) ?? '',
              classesLeft: (r['classes_left'] as num?)?.toInt(),
              classesTotal: (r['classes_total'] as num?)?.toInt(),
              validUntil: r['valid_until'] == null
                  ? null
                  : DateTime.parse(r['valid_until'] as String),
              status: MembershipStatus.fromDb(r['status'] as String?),
            ))
        .toList();
  }

  @override
  Future<List<AdminBookingRow>> getClientBookings(String clientId) async {
    final res = await _client
        .rpc('admin_get_client_bookings', params: {'p_client_id': clientId});
    return _rows(res)
        .map((r) => AdminBookingRow(
              startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
              className: (r['class_name'] as String?) ?? '',
              status: BookingStatus.fromDb(r['status'] as String?),
            ))
        .toList();
  }

  @override
  Future<int> adjustBonuses(String clientId, int amount, String reason) async {
    final res = await _client.rpc('admin_adjust_bonuses', params: {
      'p_client_id': clientId,
      'p_amount': amount,
      'p_reason': reason,
    });
    return (res as num).toInt();
  }

  // ---- Лист ожидания / записи ----
  @override
  Future<List<AdminClassBooking>> getClassBookings(String classId) async {
    final res = await _client
        .rpc('admin_get_class_bookings', params: {'p_class_id': classId});
    return _rows(res)
        .map((r) => AdminClassBooking(
              bookingId: r['booking_id'] as String,
              clientName: r['client_name'] as String?,
              clientEmail: r['client_email'] as String?,
              status: BookingStatus.fromDb(r['status'] as String?),
            ))
        .toList();
  }

  @override
  Future<List<AdminWaitlistRow>> getClassWaitlist(String classId) async {
    final res = await _client
        .rpc('admin_get_class_waitlist', params: {'p_class_id': classId});
    return _rows(res)
        .map((r) => AdminWaitlistRow(
              waitlistId: r['waitlist_id'] as String,
              clientName: r['client_name'] as String?,
              position: (r['position'] as num).toInt(),
            ))
        .toList();
  }

  @override
  Future<String> promoteWaitlist(String waitlistId) async {
    final res = await _client
        .rpc('admin_promote_waitlist', params: {'p_waitlist_id': waitlistId});
    return res as String;
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _client
        .rpc('admin_cancel_booking', params: {'p_booking_id': bookingId});
  }

  // ---- Отчёты ----
  @override
  Future<List<ReportPoint>> reportSales(DateTime from, DateTime to) async {
    final res = await _client.rpc('admin_report_sales',
        params: {'p_from': _date(from), 'p_to': _date(to)});
    return _rows(res)
        .map((r) => ReportPoint(
              day: DateTime.parse(r['day'] as String),
              value: _toD(r['revenue']),
              count: (r['cnt'] as num?)?.toInt(),
            ))
        .toList();
  }

  @override
  Future<List<ReportPoint>> reportAttendance(DateTime from, DateTime to) async {
    final res = await _client.rpc('admin_report_attendance',
        params: {'p_from': _date(from), 'p_to': _date(to)});
    return _rows(res)
        .map((r) => ReportPoint(
              day: DateTime.parse(r['day'] as String),
              value: _toD(r['bookings']),
              count: (r['bookings'] as num?)?.toInt(),
            ))
        .toList();
  }

  @override
  Future<DashboardStats> dashboardStats() async {
    final res = await _client.rpc('admin_dashboard_stats');
    final r = _rows(res).first;
    return DashboardStats(
      todayClasses: (r['today_classes'] as num?)?.toInt() ?? 0,
      todayBookings: (r['today_bookings'] as num?)?.toInt() ?? 0,
      todayRevenue: _toD(r['today_revenue']),
      totalClients: (r['total_clients'] as num?)?.toInt() ?? 0,
    );
  }
}
