import '../entities/membership.dart';
import '../entities/my_schedule_item.dart';

/// Доступ к данным личного кабинета пользователя.
abstract interface class AccountRepository {
  /// Мои занятия: записи + лист ожидания (предстоящие и прошедшие).
  Future<List<MyScheduleItem>> getMySchedule();

  /// Мои абонементы (активные и история).
  Future<List<Membership>> getMyMemberships();
}
