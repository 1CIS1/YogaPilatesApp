import '../../domain/entities/class_type.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/scheduled_class.dart';

/// Преобразование «сырых» строк из Supabase (RPC/таблицы) в доменные сущности.
class ScheduleMappers {
  ScheduleMappers._();

  static double _toDouble(Object? v) => v == null ? 0 : (v as num).toDouble();
  static int? _toIntOrNull(Object? v) => v == null ? null : (v as num).toInt();

  /// Строка результата RPC get_schedule.
  static ScheduledClass classFromRow(Map<String, dynamic> r) {
    final instructorId = r['instructor_id'] as String?;
    return ScheduledClass(
      id: r['id'] as String,
      classType: ClassType(
        id: r['class_type_id'] as String,
        name: (r['class_type_name'] as String?) ?? '',
        color: r['class_type_color'] as String?,
      ),
      instructor: instructorId == null
          ? null
          : Instructor(
              id: instructorId,
              fullName: (r['instructor_name'] as String?) ?? '',
              photoUrl: r['instructor_photo'] as String?,
              rating: _toDouble(r['instructor_rating']),
            ),
      hallName: r['hall_name'] as String?,
      startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
      capacity: (r['capacity'] as num).toInt(),
      bookedCount: (r['booked_count'] as num?)?.toInt() ?? 0,
      difficulty: DifficultyLevel.fromDb(r['difficulty'] as String?),
      status: ClassStatus.fromDb(r['status'] as String?),
      price: _toDouble(r['price']),
      isBooked: (r['is_booked'] as bool?) ?? false,
      myBookingId: r['my_booking_id'] as String?,
      myWaitlistPosition: _toIntOrNull(r['my_waitlist_position']),
    );
  }

  static ClassType classTypeFromRow(Map<String, dynamic> r) => ClassType(
        id: r['id'] as String,
        name: (r['name'] as String?) ?? '',
        color: r['color'] as String?,
      );

  static Instructor instructorFromRow(Map<String, dynamic> r) => Instructor(
        id: r['id'] as String,
        fullName: (r['full_name'] as String?) ?? '',
        photoUrl: r['photo_url'] as String?,
        rating: _toDouble(r['rating']),
      );
}
