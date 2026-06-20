/// Конфигурация приложения. Значения передаются при сборке через --dart-define,
/// чтобы секреты не попадали в репозиторий. Пример запуска — в README.
class AppConfig {
  AppConfig._();

  static const String supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  static const String oneSignalAppId =
      String.fromEnvironment('ONESIGNAL_APP_ID', defaultValue: '');

  /// Режим оплаты: 'test' (мгновенное подтверждение) или 'prod' (YooKassa
  /// через Edge Function + webhook). Передаётся через --dart-define.
  static const String paymentMode =
      String.fromEnvironment('PAYMENT_MODE', defaultValue: 'test');

  /// URL возврата после оплаты YooKassa (для закрытия WebView).
  static const String paymentReturnUrl = String.fromEnvironment(
      'PAYMENT_RETURN_URL',
      defaultValue: 'https://example.com/payment-result');

  /// Заданы ли минимально необходимые ключи для подключения к Supabase.
  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static bool get isOneSignalConfigured => oneSignalAppId.isNotEmpty;

  /// Включён ли боевой режим оплаты.
  static bool get isProdPayments => paymentMode == 'prod';
}
