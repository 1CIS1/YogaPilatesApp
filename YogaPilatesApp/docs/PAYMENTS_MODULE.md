# Модуль «Оплата» — как проверить и как включить боевой YooKassa

Покупка абонементов и разовых занятий. В этой итерации — **тест-режим**: платёж
подтверждается мгновенно, реальные деньги не списываются. Боевой YooKassa
подключается позже ключами + Edge Function (скелет уже есть).

## Что добавлено

Backend (`supabase/migrations/0005_payments.sql`):
- `create_payment(type, related_id, promo_code)` — считает сумму (промокод + персональная скидка) и создаёт платёж `pending`.
- `confirm_payment(payment_id)` — переводит платёж в `succeeded` и выполняет фулфилмент: для абонемента создаёт `client_memberships`, для разового — создаёт `booking`.
- `get_payment_status(payment_id)`.
- **Обновлены** `book_into_class` (списывает занятие с активного абонемента: count_based → −1, unlimited → бесплатно) и `cancel_booking` (возвращает занятие на абонемент при отмене).

Flutter:
- **domain**: `MembershipPlan`, `PaymentDraft`, enum'ы `PurchaseType` / `PaymentStatus`, интерфейс `PaymentRepository`.
- **data**: `PaymentRepositoryImpl` (RPC).
- **presentation**: `membershipPlansProvider`, `checkoutController`, экраны `MembershipPlansScreen` и `CheckoutScreen`.
- Интеграция: «Купить абонемент» (в «Мои абонементы») → список тарифов → оформление; «Оплатить разовое: N ₽» на экране занятия. Маршруты `/membership-plans`, `/checkout`.

## Применить миграцию

В Supabase SQL Editor выполнить `0005_payments.sql` (после 0001–0004).

## Сценарии проверки (тест-режим)

**Покупка абонемента.** Войти как client2@yoga.test (`Passw0rd!`) → Профиль → «Мои абонементы» → «Купить абонемент» → выбрать тариф → «Оплатить». После успеха: в «Моих абонементах» появляется активный абонемент.

**Списание занятия с абонемента.** Имея активный поштучный абонемент, записаться на занятие в расписании → в «Моих абонементах» остаток уменьшается на 1. Отмена записи → остаток возвращается.

**Оплата разового занятия.** Открыть занятие в расписании → «Оплатить разовое: N ₽» → «Оплатить» → создаётся запись (`booking`).

## Как включить боевой YooKassa (позже)

1. Получить `shopId` и `secretKey` в личном кабинете YooKassa (тестовый магазин для отладки, карта `4111 1111 1111 1111`).
2. Прописать секреты: `supabase secrets set YOOKASSA_SHOP_ID=... YOOKASSA_SECRET_KEY=...`.
3. Задеплоить Edge Function: `supabase functions deploy process-payment`.
4. В YooKassa указать URL webhook: `<func-url>/process-payment/webhook` на событие `payment.succeeded`.
5. В приложении ничего переписывать не нужно — включить флаг сборки
   `--dart-define=PAYMENT_MODE=prod` (+ `PAYMENT_RETURN_URL=...`). Тогда поток:
   `create_payment` → Edge Function `process-payment` (получить `confirmation_url`)
   → WebView с оплатой → опрос `get_payment_status`; подтверждение приходит из
   webhook (вызывает `confirm_payment`). По умолчанию `PAYMENT_MODE=test`.

## Замечания

- Управление состоянием — Riverpod 3 (`FutureProvider` + `AsyncNotifier`).
- Фискализация 54-ФЗ отложена: суммы и платежи хранятся (`payments`, `receipts`), реальные чеки не пробиваются. YooKassa умеет фискализацию сам (объект `receipt`) — место помечено в Edge Function.
- Таблиц `payment_items` / `checks` нет; для MVP достаточно `payments.purchase_type` + `related_id`.
