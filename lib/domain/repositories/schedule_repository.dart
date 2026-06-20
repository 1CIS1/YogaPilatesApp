import '../entities/class_type.dart';
import '../entities/enums.dart';
import '../entities/instructor.dart';
import '../entities/scheduled_class.dart';

/// Результат попытки записи на занятие.
enum BookingOutcome {
  booked, // успешно записан
  full, // мест нет — предложить лист ожидания
  alreadyBooked; // уже записан

  static BookingOutcome fromDb(String? value) => switch (value) {
        'full' => BookingOutcome.full,
        'already_booked' => BookingOutcome.alreadyBooked,
        _ => BookingOutcome.booked,
      };
}

/// Абстракция доступа к данным расписания и записи (Clean Architecture).
abstract interface class ScheduleRepository {
  /// Расписание за период с фильтрами и контекстом текущего пользователя.
  Future<List<ScheduledClass>> getSchedule({
    required DateTime from,
    required DateTime to,
    String? classTypeId,
    DifficultyLevel? difficulty,
    String? instructorId,
  });

  Future<List<ClassType>> getClassTypes();

  Future<List<Instructor>> getInstructors();

  /// Запись на занятие (атомарно на стороне БД).
  Future<BookingOutcome> bookClass(String classId);

  /// Отмена записи (с автопереносом из листа ожидания).
  Future<void> cancelBooking(String bookingId);

  /// Встать в лист ожидания. Возвращает позицию.
  Future<int> joinWaitlist(String classId);

  /// Выйти из листа ожидания.
  Future<void> leaveWaitlist(String classId);
}
