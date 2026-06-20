import 'package:flutter_test/flutter_test.dart';
import 'package:yoga_pilates_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('валидный', () => expect(Validators.email('a@b.ru'), isNull));
    test('пустой', () => expect(Validators.email(''), isNotNull));
    test('некорректный', () => expect(Validators.email('abc'), isNotNull));
  });

  group('Validators.password', () {
    test('ок', () => expect(Validators.password('123456'), isNull));
    test('короткий', () => expect(Validators.password('123'), isNotNull));
    test('пустой', () => expect(Validators.password(''), isNotNull));
  });

  group('Validators.phone', () {
    test('валидный', () => expect(Validators.phone('+79110000001'), isNull));
    test('буквы', () => expect(Validators.phone('abc'), isNotNull));
  });

  group('Validators.required', () {
    test('пустое', () => expect(Validators.required('  '), isNotNull));
    test('заполнено', () => expect(Validators.required('x'), isNull));
  });
}
