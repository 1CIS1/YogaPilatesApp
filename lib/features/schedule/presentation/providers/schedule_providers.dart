import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../data/repositories/schedule_repository_impl.dart';
import '../../../../domain/entities/class_type.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/instructor.dart';
import '../../../../domain/entities/scheduled_class.dart';
import '../../../../domain/repositories/schedule_repository.dart';

/// Репозиторий расписания.
final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Выбранный день календаря (без времени).
final selectedDayProvider =
    NotifierProvider<SelectedDayNotifier, DateTime>(SelectedDayNotifier.new);

class SelectedDayNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void select(DateTime day) => state = DateTime(day.year, day.month, day.day);
}

/// Активные фильтры расписания.
class ScheduleFilters {
  const ScheduleFilters({this.classTypeId, this.difficulty, this.instructorId});

  final String? classTypeId;
  final DifficultyLevel? difficulty;
  final String? instructorId;

  bool get isEmpty =>
      classTypeId == null && difficulty == null && instructorId == null;

  int get activeCount =>
      [classTypeId, difficulty, instructorId].where((e) => e != null).length;
}

final scheduleFiltersProvider =
    NotifierProvider<ScheduleFiltersNotifier, ScheduleFilters>(
        ScheduleFiltersNotifier.new);

class ScheduleFiltersNotifier extends Notifier<ScheduleFilters> {
  @override
  ScheduleFilters build() => const ScheduleFilters();

  void setClassType(String? id) => state = ScheduleFilters(
        classTypeId: id,
        difficulty: state.difficulty,
        instructorId: state.instructorId,
      );

  void setDifficulty(DifficultyLevel? d) => state = ScheduleFilters(
        classTypeId: state.classTypeId,
        difficulty: d,
        instructorId: state.instructorId,
      );

  void setInstructor(String? id) => state = ScheduleFilters(
        classTypeId: state.classTypeId,
        difficulty: state.difficulty,
        instructorId: id,
      );

  void clear() => state = const ScheduleFilters();
}

/// Расписание на выбранный день с учётом фильтров.
final scheduleForDayProvider = FutureProvider<List<ScheduledClass>>((ref) async {
  final day = ref.watch(selectedDayProvider);
  final filters = ref.watch(scheduleFiltersProvider);
  final repo = ref.watch(scheduleRepositoryProvider);

  final from = DateTime(day.year, day.month, day.day);
  final to = from.add(const Duration(days: 1));

  return repo.getSchedule(
    from: from,
    to: to,
    classTypeId: filters.classTypeId,
    difficulty: filters.difficulty,
    instructorId: filters.instructorId,
  );
});

/// Справочники для фильтров.
final classTypesProvider = FutureProvider<List<ClassType>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getClassTypes();
});

final instructorsProvider = FutureProvider<List<Instructor>>((ref) {
  return ref.watch(scheduleRepositoryProvider).getInstructors();
});

/// Контроллер действий записи (запись/отмена/лист ожидания).
final bookingControllerProvider =
    AsyncNotifierProvider<BookingController, void>(BookingController.new);

class BookingController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  ScheduleRepository get _repo => ref.read(scheduleRepositoryProvider);

  Future<BookingOutcome> book(String classId) async {
    state = const AsyncLoading();
    try {
      final outcome = await _repo.bookClass(classId);
      _refresh();
      state = const AsyncData(null);
      return outcome;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> cancel(String bookingId) async {
    state = const AsyncLoading();
    try {
      await _repo.cancelBooking(bookingId);
      _refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<int> joinWaitlist(String classId) async {
    state = const AsyncLoading();
    try {
      final position = await _repo.joinWaitlist(classId);
      _refresh();
      state = const AsyncData(null);
      return position;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> leaveWaitlist(String classId) async {
    state = const AsyncLoading();
    try {
      await _repo.leaveWaitlist(classId);
      _refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void _refresh() => ref.invalidate(scheduleForDayProvider);
}
