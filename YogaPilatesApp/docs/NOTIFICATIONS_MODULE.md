# Модуль «Push-уведомления» — проверка и боевое включение

Центр уведомлений, настройки, напоминания о занятиях, лист ожидания, отмена
занятия, день рождения + бонусы. Создание уведомлений и вся серверная логика
работают сразу; доставка push требует подключения OneSignal.

## Что добавлено

Backend (`supabase/migrations/0006_notifications.sql`):
- RPC: `register_push_token`, `mark_notification_read`, `mark_all_notifications_read`, `update_notify_prefs`.
- Функции-генераторы: `enqueue_class_reminders()` (за 24 ч и 2 ч, с учётом настройки «напоминания»), `enqueue_birthday_notifications(bonus)` (поздравление + начисление бонусов).
- Триггер `notify_class_cancelled` — при отмене занятия уведомляет всех записанных.
- Заготовки расписания `pg_cron` (в конце файла, закомментированы).

Edge Functions:
- `send-notification` — отправка одного push через OneSignal (по `external_user_id`).
- `dispatch-notifications` — cron-обработчик: рассылает все `queued`-уведомления, ставит `sent`.

Flutter:
- **domain**: `AppNotification`, `NotificationSettings`, `NotificationRepository`.
- **data**: мапперы + `NotificationRepositoryImpl`.
- **presentation**: `notificationsProvider`, `unreadCountProvider`, контроллеры, экраны `NotificationsScreen` (группировка по дате, прочтение, бейдж непрочитанных в навигации) и `NotificationSettingsScreen`.
- **core/push**: `OneSignalService` (push), `LocalNotificationsService` (локальные напоминания, офлайн).
- Инициализация в `main.dart`; вход/выход OneSignal по сессии в `app.dart`.

## Применить миграцию

В Supabase SQL Editor выполнить `0006_notifications.sql` (после 0001–0005).

## Проверка без OneSignal (всё, кроме реальной доставки)

Уведомления складываются в таблицу `notifications` и видны в приложении сразу:

1. **Лист ожидания / отмена.** Войти как client2 → отменить запись на занятие 09:00 (где есть очередь). У client4 в БД появится уведомление «Вы записаны!» — оно отобразится в его центре уведомлений и в бейдже навигации.
2. **Отмена занятия админом.** Изменить `scheduled_classes.status` занятия на `'cancelled'` (через SQL/будущую админку) → у всех записанных появляется «Занятие отменено».
3. **Напоминания.** Выполнить `select enqueue_class_reminders();` — создадутся напоминания для занятий через ~24 ч и ~2 ч.
4. **День рождения.** Выполнить `select enqueue_birthday_notifications();` — клиентам с ДР сегодня начислятся бонусы и придёт поздравление. (Для теста можно временно выставить `birth_date` = сегодня.)
5. В приложении: открыть «Уведомления», отметить прочитанным (бейдж уменьшается), зайти в настройки и переключить тумблеры.

## Включить реальную доставку push (OneSignal)

1. Создать приложение в OneSignal, получить **App ID** и **REST API Key**; настроить Android (FCM) и iOS (APNs).
2. Передавать App ID в сборку: `--dart-define=ONESIGNAL_APP_ID=...` (см. README).
3. Секреты для Edge Functions: `supabase secrets set ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=...`.
4. Задеплоить функции: `supabase functions deploy send-notification dispatch-notifications`.
5. Запланировать рассылку и генераторы через `pg_cron` (примеры — в конце `0006_notifications.sql`).

Приложение при старте вызывает `OneSignal.login(<uid>)`, поэтому отправка идёт по `external_user_id = Supabase user id` — отдельная таблица токенов для таргетинга не нужна (`register_push_token` оставлен на будущее).

## Замечания

- Управление состоянием — Riverpod 3 (`FutureProvider` + `AsyncNotifier`).
- Настройки уведомлений хранятся в `profiles.notify_prefs` (jsonb): `push`, `email`, `sms`, `reminders`, `news`.
- Локальные напоминания (`LocalNotificationsService`) — основа для офлайн-режима; для точного времени стоит задать локальный часовой пояс (`timezone`), сейчас используется значение по умолчанию.
- Генераторы напоминаний/ДР сделаны SQL-функциями + `pg_cron` (проще и тестируемо), а не отдельными Edge Functions — строки уведомлений появляются в БД независимо от OneSignal.
