import 'class_type.dart';
import 'enums.dart';
import 'instructor.dart';

/// Конкретное занятие в расписании.
class ScheduledClass {
  const ScheduledClass({
    required this.id,
    required this.classType,
    required this.startsAt,
    required this.endsAt,
    required this.capacity,
    required this.bookedCount,
    required this.difficulty,
    required this.status,
    required this.price,
    this.instructor,
    this.hallName,
    this.isBooked = false,
    this.myBookingId,
    this.myWaitlistPosition,
  });

  final String id;
  final ClassType classType;
  final Instructor? instructor;
  final String? hallName;
  final DateTime startsAt;
  final DateTime endsAt;
  final int capacity;
  final int bookedCount;
  final DifficultyLevel difficulty;
  final ClassStatus status;
  final double price;

  /// Контекст текущего пользователя.
  final bool isBooked;
  final String? myBookingId;
  final int? myWaitlistPosition;

  int get spotsLeft => (capacity - bookedCount).clamp(0, capacity);

  bool get isWaitlisted => myWaitlistPosition != null;

  /// Производная доступность для отображения.
  ClassAvailability get availability {
    if (status == ClassStatus.cancelled) return ClassAvailability.cancelled;
    if (spotsLeft <= 0) return ClassAvailability.full;
    if (spotsLeft <= 3) return ClassAvailability.fewSpots;
    return ClassAvailability.available;
  }
}
