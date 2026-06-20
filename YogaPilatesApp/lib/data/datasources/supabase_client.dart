import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/config/app_config.dart';

/// Обёртка над инициализацией и доступом к Supabase.
/// Сессия сохраняется автоматически (shared_preferences внутри supabase_flutter).
class SupabaseService {
  SupabaseService._();

  /// Вызывается один раз в main() до runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      anonKey: AppConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  /// Единая точка доступа к клиенту.
  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;
  static Session? get currentSession => auth.currentSession;
  static User? get currentUser => auth.currentUser;
}
