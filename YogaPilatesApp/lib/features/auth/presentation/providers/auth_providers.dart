import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../domain/entities/app_role.dart';

/// Поток событий аутентификации Supabase (вход/выход/обновление токена).
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

/// Текущая сессия (null — пользователь не авторизован).
final currentSessionProvider = Provider<Session?>((ref) {
  // Перечитываем при каждом событии auth, но fallback — на текущую сессию.
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentSession;
});

/// Авторизован ли пользователь.
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentSessionProvider) != null;
});

/// Контроллер роли текущего пользователя: тянет profiles.role из БД.
final roleControllerProvider =
    AsyncNotifierProvider<RoleController, AppRole?>(RoleController.new);

class RoleController extends AsyncNotifier<AppRole?> {
  @override
  Future<AppRole?> build() async {
    // Пересчитываемся при смене сессии.
    final session = ref.watch(currentSessionProvider);
    if (session == null) return null;

    final client = ref.watch(supabaseClientProvider);
    final data = await client
        .from('profiles')
        .select('role')
        .eq('id', session.user.id)
        .maybeSingle();

    if (data == null) return AppRole.client;
    return AppRole.fromDb(data['role'] as String?);
  }
}

/// Является ли текущий пользователь персоналом (для гварда админ-панели).
final isStaffProvider = Provider<bool>((ref) {
  return ref.watch(roleControllerProvider).valueOrNull?.isStaff ?? false;
});

/// Действия аутентификации (вход/выход). Заглушка под расширение.
final authActionsProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref.watch(supabaseClientProvider));
});

class AuthActions {
  AuthActions(this._client);
  final SupabaseClient _client;

  Future<void> signInWithPassword(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password) async {
    await _client.auth.signUp(email: email, password: password);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }
}
