import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/di/providers.dart';
import 'core/navigation/app_router.dart';
import 'core/push/onesignal_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_providers.dart';

/// Корневой виджет приложения: тема + роутер + локализация.
class YogaPilatesApp extends ConsumerWidget {
  const YogaPilatesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Привязываем/отвязываем push-подписку OneSignal при входе/выходе.
    ref.listen(currentSessionProvider, (prev, next) {
      if (next != null) {
        OneSignalService.login(next.user.id);
      } else {
        OneSignalService.logout();
      }
    });

    return MaterialApp.router(
      title: 'Йога & Пилатес',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
