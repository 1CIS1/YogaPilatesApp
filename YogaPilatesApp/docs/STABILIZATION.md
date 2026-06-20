# Стабилизация MVP — тесты, CI, известные доработки

## Добавлено

**Тесты** (`test/`):
- `domain/enums_test.dart` — мапперы enum'ов (difficulty, booking, membership, purchase, payment).
- `domain/entities_test.dart` — `ScheduledClass.availability/spotsLeft`, `Membership.usageProgress`, `MembershipPlan.summary`.
- `domain/notification_settings_test.dart` — сериализация настроек.
- `core/validators_test.dart` — валидаторы форм.
- `widget/simple_bar_chart_test.dart` — рендер графика и пустое состояние.

**CI** (`.github/workflows/ci.yml`): `flutter pub get` → `flutter analyze` → `flutter test --coverage` → debug-сборка APK.

## Как прогнать локально

```bash
flutter pub get
flutter analyze
flutter test
```

> Тесты покрывают чистую бизнес-логику (без сети). Логика на стороне БД
> (RPC, триггеры) проверяется SQL-сценариями из `docs/*_MODULE.md`.

## Исправлено в этой итерации

- `confirm_payment` (single_class): добавлена блокировка строки занятия и проверка свободных мест — защита от овербукинга при оплате разового.

## Известные доработки (бэклог)

Найдено при ревизии — рекомендуется закрыть до релиза или на Этапе 2:

1. **Редактирование профиля клиентом** (ТЗ 5.1) — сейчас в кабинете только просмотр. Нужна форма (имя, телефон, email, дата рождения) + RPC `update_my_profile`.
2. **UI промокода в чекауте** — поле есть, но скидка не показывается до оплаты (считается на сервере). Добавить предпросчёт суммы.
3. **Локальные напоминания** — `LocalNotificationsService` использует `tz.local` по умолчанию (UTC). Для точного времени задать часовой пояс устройства (`flutter_timezone`).
4. **DropdownButtonFormField(value:)** — на новых версиях Flutter может давать deprecation-warning; при необходимости перейти на `initialValue`.

## Не вошло в MVP (из ТЗ — кандидаты на Этап 2/3)

Правила студии с обязательным принятием; договоры (генерация + ЭП); новости / о студии / фотогалерея; отзывы и рейтинги занятий; кнопки связи с админом (Telegram/WhatsApp/звонок); Apple/Google Pay; подарочные сертификаты; вход через соцсети; QR-чекин; экран Audit Log (данные уже пишутся в `audit_log`); CRUD тарифов и редактирование клиента в админке.
