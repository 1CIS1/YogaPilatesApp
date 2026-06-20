import 'enums.dart';

/// Запись клиента на занятие.
class Booking {
  const Booking({
    required this.id,
    required this.scheduledClassId,
    required this.status,
    required this.bookedAt,
  });

  final String id;
  final String scheduledClassId;
  final BookingStatus status;
  final DateTime bookedAt;
}
