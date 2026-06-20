import '../entities/admin_entities.dart';
import '../entities/enums.dart';

/// Доступ к админ-операциям (через security-definer RPC).
abstract interface class AdminRepository {
  // Расписание
  Future<List<AdminClass>> getClasses(DateTime from, DateTime to);
  Future<String> createClass({
    required String classTypeId,
    String? instructorId,
    String? hallId,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    required DifficultyLevel difficulty,
    required double price,
  });
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
  });
  Future<void> cancelClass(String id);
  Future<List<AdminHall>> getHalls();

  // Клиенты
  Future<List<AdminClient>> getClients(String? search);
  Future<AdminClientDetails> getClientDetails(String clientId);
  Future<List<AdminMembershipRow>> getClientMemberships(String clientId);
  Future<List<AdminBookingRow>> getClientBookings(String clientId);
  Future<int> adjustBonuses(String clientId, int amount, String reason);

  // Лист ожидания / записи
  Future<List<AdminClassBooking>> getClassBookings(String classId);
  Future<List<AdminWaitlistRow>> getClassWaitlist(String classId);
  Future<String> promoteWaitlist(String waitlistId);
  Future<void> cancelBooking(String bookingId);

  // Отчёты
  Future<List<ReportPoint>> reportSales(DateTime from, DateTime to);
  Future<List<ReportPoint>> reportAttendance(DateTime from, DateTime to);
  Future<DashboardStats> dashboardStats();
}
