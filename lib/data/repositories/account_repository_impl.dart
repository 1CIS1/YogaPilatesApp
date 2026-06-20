import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/membership.dart';
import '../../domain/entities/my_schedule_item.dart';
import '../../domain/repositories/account_repository.dart';
import '../mappers/account_mappers.dart';

/// Реализация репозитория личного кабинета поверх Supabase RPC.
class AccountRepositoryImpl implements AccountRepository {
  AccountRepositoryImpl(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MyScheduleItem>> getMySchedule() async {
    final res = await _client.rpc('get_my_schedule');
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(AccountMappers.scheduleItemFromRow).toList();
  }

  @override
  Future<List<Membership>> getMyMemberships() async {
    final res = await _client.rpc('get_my_memberships');
    final rows = (res as List).cast<Map<String, dynamic>>();
    return rows.map(AccountMappers.membershipFromRow).toList();
  }
}
