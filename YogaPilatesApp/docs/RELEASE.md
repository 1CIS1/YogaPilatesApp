# Подготовка к публикации — пошаговый гайд

Сборка и выпуск приложения в Google Play и App Store. Блоки, которые нельзя
подготовить в репозитории (нативные манифесты живут в твоей рабочей копии,
ключи и аккаунты — у тебя), даны готовыми для вставки.

---

## 1. Иконки и сплэш

Конфиг уже в `pubspec.yaml` (секции `flutter_launcher_icons` и
`flutter_native_splash`). Экспортируй PNG из `assets/icon/*.svg`
(см. `assets/icon/README.md`) и выполни:

```bash
flutter pub get
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

---

## 2. Android — AndroidManifest.xml

Файл: `android/app/src/main/AndroidManifest.xml`.

**Разрешения** (внутри `<manifest>`, до `<application>`):

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.VIBRATE"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
```

**Тег `<application>`** — атрибуты:

```xml
<application
    android:label="Йога & Пилатес"
    android:icon="@mipmap/ic_launcher"
    android:allowBackup="true"
    android:usesCleartextTraffic="false"
    android:dataExtractionRules="@xml/data_extraction_rules"
    android:fullBackupContent="@xml/backup_rules"
    ... >
```

**Запросы к мессенджерам** (для кнопок «связь с админом», секция `<queries>`):

```xml
<queries>
    <package android:name="org.telegram.messenger"/>
    <package android:name="com.whatsapp"/>
    <package android:name="com.viber.voip"/>
    <intent>
        <action android:name="android.intent.action.VIEW"/>
        <data android:scheme="https"/>
    </intent>
</queries>
```

**Версия / SDK** — `android/app/build.gradle` (или `build.gradle.kts`):
`minSdkVersion 21`, `targetSdkVersion` = последний, `compileSdkVersion` = последний.
`flutter_local_notifications` требует `minSdk >= 21`.

> `android:requestLegacyExternalStorage` не нужен — файловую систему мы не используем.

---

## 3. iOS — Info.plist

Файл: `ios/Runner/Info.plist` (добавить пары ключ-значение):

```xml
<key>CFBundleDisplayName</key>
<string>Йога &amp; Пилатес</string>
<key>CFBundleName</key>
<string>YogaPilates</string>

<!-- Push -->
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>

<!-- Схемы мессенджеров для кнопок связи -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>tg</string>
    <string>whatsapp</string>
    <string>viber</string>
</array>
```

> Камеру/галерею/геолокацию в MVP не используем — соответствующие
> `NS*UsageDescription` НЕ добавляем (иначе ревью App Store спросит, зачем).
> Текст разрешения на уведомления управляется OneSignal/системой.

---

## 4. Боевые ключи и конфигурация

**Клиент (сборка):** ключи передаются через `--dart-define` (см. `AppConfig`):

```bash
--dart-define=SUPABASE_URL=https://<project>.supabase.co
--dart-define=SUPABASE_ANON_KEY=<anon-key>
--dart-define=ONESIGNAL_APP_ID=<app-id>
```

**Сервер (Edge Functions):** секреты только на сервере:

```bash
supabase secrets set \
  ONESIGNAL_APP_ID=... ONESIGNAL_REST_API_KEY=... \
  YOOKASSA_SHOP_ID=... YOOKASSA_SECRET_KEY=...
```

**Деплой функций:**

```bash
supabase functions deploy dispatch-notifications
supabase functions deploy send-notification
supabase functions deploy process-payment
```

**Webhook YooKassa:** в личном кабинете указать
`https://<project>.functions.supabase.co/process-payment/webhook`
на событие `payment.succeeded`.

**Переключение режима оплаты (test → prod).** Менять код не нужно — режим
управляется флагом сборки:

```bash
# Боевой режим: страница оплаты YooKassa в WebView + подтверждение из webhook
--dart-define=PAYMENT_MODE=prod
--dart-define=PAYMENT_RETURN_URL=https://<ваш-домен>/payment-result
```

По умолчанию `PAYMENT_MODE=test` (мгновенное подтверждение, для разработки).
В prod-режиме приложение: создаёт платёж (`create_payment`) → вызывает Edge
Function `process-payment` → открывает `confirmation_url` в WebView → после
оплаты опрашивает `get_payment_status` (подтверждение приходит из webhook,
который вызывает `confirm_payment`). `return_url` в YooKassa должен начинаться
с `PAYMENT_RETURN_URL` — по нему WebView закрывается.

**Применить все миграции БД** по порядку: `0001 → 0007` (+ включить `pg_cron`
и раскомментировать расписание из `0006_notifications.sql`).

---

## 5. Firebase (FCM) и OneSignal

1. **OneSignal** → создать приложение, получить **App ID** и **REST API Key**.
2. **Android (FCM):** в Firebase Console создать проект, скачать
   `google-services.json` → положить в `android/app/`. В OneSignal загрузить
   ключ FCM (Service Account JSON).
3. **iOS (APNs):** в Apple Developer создать APNs Key (.p8) → загрузить в OneSignal.
   `GoogleService-Info.plist` (если используешь Firebase) → в `ios/Runner/`.
4. В приложении `OneSignalService.init()` уже вызывается в `main.dart`, а
   `OneSignal.login(<uid>)` — в `app.dart` при входе. Достаточно передать
   `ONESIGNAL_APP_ID` в сборку.

> Оба файла (`google-services.json`, `GoogleService-Info.plist`) — в `.gitignore`.

---

## 6. Подпись и сборка релизов

**Android — подпись.** Создать keystore и `android/key.properties`
(шаблон: `android/key.properties.example`). В `android/app/build.gradle`
до `android { }` добавить чтение свойств, а в `buildTypes.release` — `signingConfig`:

```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}

android {
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**Сборка Android:**

```bash
flutter build appbundle --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=ONESIGNAL_APP_ID=...
# APK по ABI (опционально):
flutter build apk --release --split-per-abi --dart-define=...
```

**iOS:** в Xcode настроить Team, Bundle ID, сертификаты и provisioning profiles
(Signing & Capabilities → включить Push Notifications). Затем:

```bash
flutter build ipa --release \
  --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... \
  --dart-define=ONESIGNAL_APP_ID=...
```

**CI для релиза** (расширение `ci.yml`): хранить keystore (base64) и ключи в
GitHub Secrets, декодировать на раннере, передавать `--dart-define` из секретов.
Релизные шаги вынести в отдельный workflow по тегу `v*`.

---

## 7. Материалы для магазинов

См. `docs/STORE_LISTING.md` (описания, ключевые слова, план скриншотов) и
`docs/PRIVACY_POLICY.md` (шаблон политики конфиденциальности — обяз. для обоих
магазинов, нужна публичная ссылка).

Иконки магазинов: Google Play — 512×512 PNG; App Store — 1024×1024 PNG (без альфы).
Скриншоты: Play — от 1080×1920; App Store — 1290×2796 (6.7") и 1242×2208 (5.5").

---

## 8. Публикация — чек-лист

**Google Play:**
1. Аккаунт разработчика (разовый платёж $25).
2. Play Console → создать приложение, заполнить карточку (из `STORE_LISTING.md`).
3. Загрузить `.aab` в трек **Internal testing**.
4. Декларации: Data safety, контентный рейтинг, целевая аудитория, реклама — нет.
5. Политика конфиденциальности (ссылка).
6. Внутреннее → закрытое → открытое тестирование → прод.

**App Store:**
1. Аккаунт Apple Developer ($99/год).
2. App Store Connect → создать приложение (Bundle ID).
3. Загрузить `.ipa` через Xcode/Transporter.
4. Заполнить метаданные, скриншоты, рейтинг, политику.
5. TestFlight (внутреннее тестирование) → Submit for Review.

> Важно для App Store: продажа абонементов на **офлайн-услуги** (реальные занятия)
> допускается через внешний эквайринг — обязательный IAP не требуется. В описании
> и интерфейсе это должно читаться однозначно, иначе риск реджекта.

---

## Финальный прогон перед сабмитом

```bash
flutter pub get
flutter analyze
flutter test
flutter build appbundle --release --dart-define=...   # Android
flutter build ipa --release --dart-define=...          # iOS
```

Прогнать вручную ключевые сценарии на реальных устройствах (вход, запись,
оплата тест-карта `4111 1111 1111 1111`, push, админ-действия).
