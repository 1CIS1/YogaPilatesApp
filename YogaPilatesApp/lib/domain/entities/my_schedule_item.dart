import 'enums.dart';

enum MyItemKind { booking, waitlist }

/// Элемент личного расписания: запись или позиция в листе ожидания.
class MyScheduleItem {
  const MyScheduleItem({
    required this.itemId,
    required this.kind,
    required this.scheduledClassId,
    required this.startsAt,
    required this.endsAt,
    required this.classTypeName,
    required this.isPast,
    this.classTypeColor,
    this.instructorName,
    this.hallName,
    this.bookingStatus,
    this.waitlistPosition,
  });

  final String itemId; // id записи или id позиции в листе ожидания
  final MyItemKind kind;
  final String scheduledClassId;
  final DateTime startsAt;
  final DateTime endsAt;
  final String classTypeName;
  final String? classTypeColor;
  final String? instructorName;
  final String? hallName;
  final BookingStatus? bookingStatus;
  final int? waitlistPosition;
  final bool isPast;

  bool get isWaitlist => kind == MyItemKind.waitlist;

  /// Активная предстоящая запись (можно отменить).
  bool get isActiveBooking =>
      kind == MyItemKind.booking &&
      bookingStatus == BookingStatus.booked &&
      !isPast;

  /// Идёт ли элемент в раздел «Предстоящие».
  bool get isUpcoming => isWaitlist || isActiveBooking;
}
