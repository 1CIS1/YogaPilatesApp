import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../data/repositories/admin_repository_impl.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/repositories/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepositoryImpl(ref.watch(supabaseClientProvider));
});

// ---- Расписание ----
final adminSelectedDayProvider =
    NotifierProvider<AdminSelectedDayNotifier, DateTime>(
        AdminSelectedDayNotifier.new);

class AdminSelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

final adminClassesProvider = FutureProvider<List<AdminClass>>((ref) {
  final day = ref.watch(adminSelectedDayProvider);
  final from = DateTime(day.year, day.month, day.day);
  final to = from.add(const Duration(days: 1));
  return ref.watch(adminRepositoryProvider).getClasses(from, to);
});

final adminHallsProvider = FutureProvider<List<AdminHall>>((ref) {
  return ref.watch(adminRepositoryProvider).getHalls();
});

// ---- Клиенты ----
final adminClientsSearchProvider =
    NotifierProvider<AdminSearchNotifier, String>(AdminSearchNotifier.new);

class AdminSearchNotifier extends Notifier<String> {
  @override
  String build() => '';
  void set(String value) => state = value;
}

final adminClientsProvider = FutureProvider<List<AdminClient>>((ref) {
  final search = ref.watch(adminClientsSearchProvider);
  return ref.watch(adminRepositoryProvider).getClients(search);
});

final adminClientDetailsProvider =
    FutureProvider.family<AdminClientDetails, String>((ref, clientId) {
  return ref.watch(adminRepositoryProvider).getClientDetails(clientId);
});

final adminClientMembershipsProvider =
    FutureProvider.family<List<AdminMembershipRow>, String>((ref, clientId) {
  return ref.watch(adminRepositoryProvider).getClientMemberships(clientId);
});

final adminClientBookingsProvider =
    FutureProvider.family<List<AdminBookingRow>, String>((ref, clientId) {
  return ref.watch(adminRepositoryProvider).getClientBookings(clientId);
});

// ---- Лист ожидания ----
final adminClassBookingsProvider =
    FutureProvider.family<List<AdminClassBooking>, String>((ref, classId) {
  return ref.watch(adminRepositoryProvider).getClassBookings(classId);
});

final adminClassWaitlistProvider =
    FutureProvider.family<List<AdminWaitlistRow>, String>((ref, classId) {
  return ref.watch(adminRepositoryProvider).getClassWaitlist(classId);
});

// ---- Отчёты / дашборд ----
final adminDashboardStatsProvider = FutureProvider<DashboardStats>((ref) {
  return ref.watch(adminRepositoryProvider).dashboardStats();
});

final salesReportProvider = FutureProvider<List<ReportPoint>>((ref) {
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 13));
  return ref.watch(adminRepositoryProvider).reportSales(from, to);
});

final attendanceReportProvider = FutureProvider<List<ReportPoint>>((ref) {
  final to = DateTime.now();
  final from = to.subtract(const Duration(days: 13));
  return ref.watch(adminRepositoryProvider).reportAttendance(from, to);
});

// ---- Контроллер мутаций ----
final adminControllerProvider =
    AsyncNotifierProvider<AdminController, void>(AdminController.new);

class AdminController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  AdminRepository get _repo => ref.read(adminRepositoryProvider);

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
    final id = await _repo.createClass(
      classTypeId: classTypeId,
      instructorId: instructorId,
      hallId: hallId,
      startsAt: startsAt,
      endsAt: endsAt,
      capacity: capacity,
      difficulty: difficulty,
      price: price,
    );
    ref.invalidate(adminClassesProvider);
    return id;
  }

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
    await _repo.updateClass(
      id: id,
      classTypeId: classTypeId,
      instructorId: instructorId,
      hallId: hallId,
      startsAt: startsAt,
      endsAt: endsAt,
      capacity: capacity,
      difficulty: difficulty,
      price: price,
    );
    ref.invalidate(adminClassesProvider);
  }

  Future<void> cancelClass(String id) async {
    await _repo.cancelClass(id);
    ref.invalidate(adminClassesProvider);
  }

  Future<int> adjustBonuses(String clientId, int amount, String reason) async {
    final balance = await _repo.adjustBonuses(clientId, amount, reason);
    ref.invalidate(adminClientDetailsProvider(clientId));
    return balance;
  }

  Future<String> promoteWaitlist(String waitlistId, String classId) async {
    final r = await _repo.promoteWaitlist(waitlistId);
    ref.invalidate(adminClassWaitlistProvider(classId));
    ref.invalidate(adminClassBookingsProvider(classId));
    ref.invalidate(adminClassesProvider);
    return r;
  }

  Future<void> cancelBooking(String bookingId, String classId) async {
    await _repo.cancelBooking(bookingId);
    ref.invalidate(adminClassBookingsProvider(classId));
    ref.invalidate(adminClassWaitlistProvider(classId));
    ref.invalidate(adminClassesProvider);
  }
}
