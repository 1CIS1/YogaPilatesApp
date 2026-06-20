# Модуль «Админ-панель» (базовый) — проверка

Управление расписанием, клиентами, листом ожидания, бонусами + простые отчёты.
Все операции — через security-definer RPC с проверкой `is_staff()`; действия
пишутся в `audit_log`.

## Что добавлено

Backend (`supabase/migrations/0007_admin.sql`):
- Расписание: `admin_get_classes`, `admin_create_class`, `admin_update_class`, `admin_cancel_class`, `admin_get_halls`.
- Клиенты: `admin_get_clients`, `admin_get_client`, `admin_get_client_memberships`, `admin_get_client_bookings`, `admin_adjust_bonuses`.
- Лист ожидания: `admin_get_class_bookings`, `admin_get_class_waitlist`, `admin_promote_waitlist`, `admin_cancel_booking`.
- Отчёты: `admin_report_sales`, `admin_report_attendance`, `admin_dashboard_stats`.
- Каждая операция логируется в `audit_log` (экран-просмотрщик — на Этап 2).

Flutter (feature `admin`):
- **domain**: `admin_entities.dart` (AdminClass, AdminClient, карточка, waitlist, отчёты, статистика), `AdminRepository`.
- **data**: `AdminRepositoryImpl` (RPC).
- **presentation**: провайдеры (день, поиск, family по клиенту/занятию, отчёты, контроллер мутаций) и экраны:
  - `AdminDashboardScreen` — статистика + навигация;
  - `AdminClassesScreen` — список занятий по дням, создание/правка/отмена;
  - `AdminClassFormScreen` — форма занятия (тип, преподаватель, зал, время, сложность, лимит, цена);
  - `AdminClientsScreen` — поиск и список клиентов;
  - `AdminClientProfileScreen` — карточка: данные, бонусы (±), абонементы, последние занятия;
  - `AdminClassWaitlistScreen` — записи (снять) и лист ожидания (перенести в запись);
  - `AdminReportsScreen` — продажи и посещаемость (лёгкие графики без зависимостей).
- Доступ только для роли персонала (гвард `/admin*` в роутере уже был).

## Применить миграцию

В Supabase SQL Editor выполнить `0007_admin.sql` (после 0001–0006).

## Сценарий проверки

Войти как **admin@yoga.test** (`Passw0rd!`) → Профиль → «Админ-панель»:
1. **Дашборд** — занятия/записи/выручка за сегодня, всего клиентов.
2. **Расписание** — создать занятие (FAB), отредактировать, отменить (записанным придёт уведомление — триггер из модуля уведомлений).
3. **Клиенты** — найти client1, открыть карточку, начислить +100 бонусов; проверить, что баланс вырос (и появилась запись в `bonus_transactions`).
4. **Лист ожидания** — у занятия с очередью (09:00 из seed) нажать «В запись» на первом из листа → он переносится в записи.
5. **Отчёты** — два графика за 14 дней (продажи появятся после тестовых оплат).

## Замечания

- Управление состоянием — Riverpod 3 (`FutureProvider`/`.family` + `AsyncNotifier`).
- Отложено на Этап 2: расширенные отчёты, экран Audit Log (данные уже пишутся), CRUD тарифов абонементов, редактирование профиля клиента (сейчас просмотр + бонусы).
