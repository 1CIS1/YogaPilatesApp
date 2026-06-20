import 'enums.dart';

/// Занятие в админ-списке.
class AdminClass {
  const AdminClass({
    required this.id,
    required this.classTypeId,
    required this.classTypeName,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.bookedCount,
    required this.difficulty,
    required this.status,
    required this.price,
    this.instructorId,
    this.instructorName,
    this.hallId,
    this.hallName,
  });

  final String id;
  final String classTypeId;
  final String classTypeName;
  final String? instructorId;
  final String? instructorName;
  final String? hallId;
  final String? hallName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int bookedCount;
  final DifficultyLevel difficulty;
  final ClassStatus status;
  final double price;

  int get spotsLeft => (capacity - bookedCount).clamp(0, capacity);
}

/// Зал (для формы занятия).
class AdminHall {
  const AdminHall({required this.id, required this.name, required this.capacity});
  final String id;
  final String name;
  final int capacity;
}

/// Клиент в списке.
class AdminClient {
  const AdminClient({
    required this.id,
    required this.tier,
    required this.isBlocked,
    this.fullName,
    this.phone,
    this.email,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final String tier;
  final bool isBlocked;
}

/// Детали клиента (карточка).
class AdminClientDetails {
  const AdminClientDetails({
    required this.id,
    required this.tier,
    required this.isBlocked,
    required this.bonusBalance,
    this.fullName,
    this.phone,
    this.email,
    this.birthDate,
  });

  final String id;
  final String? fullName;
  final String? phone;
  final String? email;
  final DateTime? birthDate;
  final String tier;
  final bool isBlocked;
  final int bonusBalance;
}

class AdminMembershipRow {
  const AdminMembershipRow({
    required this.planName,
    required this.status,
    this.classesLeft,
    this.classesTotal,
    this.validUntil,
  });

  final String planName;
  final MembershipStatus status;
  final int? classesLeft;
  final int? classesTotal;
  final DateTime? validUntil;
}

class AdminBookingRow {
  const AdminBookingRow({
    required this.startsAt,
    required this.className,
    required this.status,
  });

  final DateTime startsAt;
  final String className;
  final BookingStatus status;
}

/// Запись на занятие (для управления листом ожидания).
class AdminClassBooking {
  const AdminClassBooking({
    required this.bookingId,
    required this.status,
    this.clientName,
    this.clientEmail,
  });

  final String bookingId;
  final String? clientName;
  final String? clientEmail;
  final BookingStatus status;
}

class AdminWaitlistRow {
  const AdminWaitlistRow({
    required this.waitlistId,
    required this.position,
    this.clientName,
  });

  final String waitlistId;
  final String? clientName;
  final int position;
}

/// Точка отчёта (день → значение).
class ReportPoint {
  const ReportPoint({required this.day, required this.value, this.count});
  final DateTime day;
  final double value;
  final int? count;
}

class DashboardStats {
  const DashboardStats({
    required this.todayClasses,
    required this.todayBookings,
    required this.todayRevenue,
    required this.totalClients,
  });

  final int todayClasses;
  final int todayBookings;
  final double todayRevenue;
  final int totalClients;
}
