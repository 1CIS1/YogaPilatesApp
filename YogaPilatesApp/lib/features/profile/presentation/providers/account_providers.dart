import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../data/repositories/account_repository_impl.dart';
import '../../../../domain/entities/membership.dart';
import '../../../../domain/entities/my_schedule_item.dart';
import '../../../../domain/repositories/account_repository.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';

/// Репозиторий личного кабинета.
final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepositoryImpl(ref.watch(supabaseClientProvider));
});

/// Мои занятия (записи + лист ожидания).
final myScheduleProvider = FutureProvider<List<MyScheduleItem>>((ref) {
  return ref.watch(accountRepositoryProvider).getMySchedule();
});

/// Мои абонементы.
final myMembershipsProvider = FutureProvider<List<Membership>>((ref) {
  return ref.watch(accountRepositoryProvider).getMyMemberships();
});

/// Действия в личном кабинете (отмена записи / выход из листа ожидания).
final accountControllerProvider =
    AsyncNotifierProvider<AccountController, void>(AccountController.new);

class AccountController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> cancelBooking(String bookingId) async {
    state = const AsyncLoading();
    try {
      // Переиспользуем общий метод репозитория расписания (RPC cancel_booking).
      await ref.read(scheduleRepositoryProvider).cancelBooking(bookingId);
      _refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> leaveWaitlist(String classId) async {
    state = const AsyncLoading();
    try {
      await ref.read(scheduleRepositoryProvider).leaveWaitlist(classId);
      _refresh();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  void _refresh() {
    ref.invalidate(myScheduleProvider);
    ref.invalidate(scheduleForDayProvider);
  }
}
