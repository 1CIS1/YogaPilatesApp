import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/push/local_notifications_service.dart';
import 'core/push/onesignal_service.dart';
import 'data/datasources/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Локализация дат (календарь расписания, форматирование на русском).
  await initializeDateFormatting('ru_RU', null);
  Intl.defaultLocale = 'ru_RU';

  // Без ключей Supabase приложение не сможет работать — показываем подсказку,
  // а не падаем с ошибкой инициализации.
  if (!AppConfig.isSupabaseConfigured) {
    runApp(const _MisconfiguredApp());
    return;
  }

  await SupabaseService.initialize();

  // Push и локальные уведомления (безопасно работают и без ключей).
  await LocalNotificationsService.init();
  await OneSignalService.init();

  runApp(const ProviderScope(child: YogaPilatesApp()));
}

/// Экран-подсказка, если не переданы переменные сборки SUPABASE_URL / ANON_KEY.
class _MisconfiguredApp extends StatelessWidget {
  const _MisconfiguredApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.warning_amber_rounded, size: 64),
                SizedBox(height: 16),
                Text(
                  'Не заданы ключи Supabase',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Запустите приложение с параметрами:\n'
                  '--dart-define=SUPABASE_URL=...\n'
                  '--dart-define=SUPABASE_ANON_KEY=...\n\n'
                  'Подробнее — в README.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
