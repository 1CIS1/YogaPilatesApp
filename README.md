# Yoga & Pilates App — Flutter (каркас)

Кроссплатформенное приложение студии йоги и пилатеса (iOS + Android).
Этот пакет — **каркас проекта (Этап 1)**: структура, тема, навигация, подключение Supabase и экраны-заглушки. Бизнес-логика фич подключается поверх.

## Стек

Flutter · Riverpod 3 · go_router 17 · Supabase (Auth/Postgres/Realtime/Storage) · Hive (офлайн-кэш) · OneSignal (push).

## Требования

- Flutter SDK ≥ 3.27, Dart ≥ 3.6
- Аккаунт и проект [Supabase](https://supabase.com)
- Xcode (для iOS), Android Studio / Android SDK (для Android)

## Установка

```bash
flutter pub get
```

Если pub ругается на ограничения версий:

```bash
flutter pub upgrade --major-versions
```

## Переменные окружения (ключи)

Секреты **не хранятся в коде** — они передаются при запуске через `--dart-define`.
Список ключей — в `.env.example`. Получить их можно в панели Supabase:
`Project Settings → API` (Project URL и `anon` public key).

## Запуск

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=ONESIGNAL_APP_ID=<id>
```

Удобно вынести это в VS Code `launch.json` (секция `args` → `--dart-define=...`).
Если ключи не переданы — приложение покажет экран-подсказку вместо падения.

## Подготовка базы данных

Схема БД лежит отдельно (`schema.sql` из пакета документации). Применить:
выполнить `schema.sql` в `Supabase → SQL Editor`, либо через Supabase CLI
(`supabase db push` с миграциями в `supabase/migrations/`).

## Сборка релизов

```bash
flutter build appbundle --release   # Android → .aab (Google Play)
flutter build ipa --release         # iOS → .ipa (App Store / TestFlight)
```

(Те же `--dart-define` нужно передавать и при сборке релиза.)

## Структура проекта

```
lib/
├── main.dart            # точка входа, инициализация Supabase
├── app.dart             # MaterialApp.router + тема + локализация
├── core/
│   ├── config/          # AppConfig (dart-define ключи)
│   ├── di/              # глобальные провайдеры (Riverpod)
│   ├── navigation/      # GoRouter, guards, нижняя навигация
│   ├── theme/           # цвета и темы (свет/тёмная)
│   ├── utils/           # валидаторы и хелперы
│   └── widgets/         # общие виджеты
├── data/
│   └── datasources/     # SupabaseService (init, сессия, realtime, storage)
├── domain/
│   └── entities/        # доменные сущности (AppRole, …)
└── features/            # фичи: auth, schedule, profile, admin, notifications
    └── <feature>/presentation/{screens,providers}
```

> Слои `data/repositories`, `data/models`, `domain/usecases` наполняются по мере
> реализации фич (расписание, оплата и т.д.).

## Тесты

```bash
flutter test
```

## Что дальше

Следующий модуль — **расписание + запись с листом ожидания**: репозиторий поверх
Supabase, провайдеры, календарь (table_calendar), фильтры и экран записи.
