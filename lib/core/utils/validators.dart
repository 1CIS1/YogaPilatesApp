/// Простые валидаторы для форм (вход, регистрация, профиль).
class Validators {
  Validators._();

  static final _emailRegExp = RegExp(r'^[\w.\-]+@([\w\-]+\.)+[\w\-]{2,}$');

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите email';
    if (!_emailRegExp.hasMatch(v)) return 'Некорректный email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Введите пароль';
    if (v.length < 6) return 'Минимум 6 символов';
    return null;
  }

  static String? required(String? value, {String field = 'Поле'}) {
    if ((value?.trim() ?? '').isEmpty) return '$field обязательно';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Введите телефон';
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(v)) return 'Некорректный телефон';
    return null;
  }
}
