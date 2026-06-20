import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/class_type.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/instructor.dart';
import '../../domain/entities/scheduled_class.dart';
import '../../domain/repositories/schedule_repository.dart';
import '../mappers/schedule_mappers.dart';

/// Реализация репозитория расписания поверх Supabase (RPC + REST).
class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ScheduledClass>> getSchedule({
    required DateTime from,
    required DateTime to,
    String? classTypeId,
    DifficultyLevel? difficulty,
    String? instructorId,
  }) async {
    final res = await _client.rpc('get_schedule', params: {
      'p_from': from.toUtc().toIso8601String(),
      'p_to': to.toUtc().toIso8601String(),
      'p_class_type': classTypeId,
      'p_difficulty': difficulty?.dbValue,
      'p_instructor': instructorId,
    });
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(ScheduleMappers.classFromRow).toList();
  }

  @override
  Future<List<ClassType>> getClassTypes() async {
    final res = await _client
        .from('class_types')
        .select('id, name, color')
        .eq('is_active', true)
        .order('name');
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(ScheduleMappers.classTypeFromRow).toList();
  }

  @override
  Future<List<Instructor>> getInstructors() async {
    final res = await _client
        .from('instructors')
        .select('id, full_name, photo_url, rating')
        .eq('is_active', true)
        .order('full_name');
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(ScheduleMappers.instructorFromRow).toList();
  }

  @override
  Future<BookingOutcome> bookClass(String classId) async {
    final res =
        await _client.rpc('book_into_class', params: {'p_class_id': classId});
    return BookingOutcome.fromDb(res as String?);
  }

  @override
  Future<void> cancelBooking(String bookingId) async {
    await _client.rpc('cancel_booking', params: {'p_booking_id': bookingId});
  }

  @override
  Future<int> joinWaitlist(String classId) async {
    final res =
        await _client.rpc('join_waitlist', params: {'p_class_id': classId});
    return (res as num).toInt();
  }

  @override
  Future<void> leaveWaitlist(String classId) async {
    await _client.rpc('leave_waitlist', params: {'p_class_id': classId});
  }
}
