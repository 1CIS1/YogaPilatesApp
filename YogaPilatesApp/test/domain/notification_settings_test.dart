import 'package:flutter_test/flutter_test.dart';
import 'package:yoga_pilates_app/domain/entities/notification_settings.dart';

void main() {
  group('NotificationSettings', () {
    test('значения по умолчанию', () {
      final s = NotificationSettings.fromJson(null);
      expect(s.push, isTrue);
      expect(s.email, isTrue);
      expect(s.sms, isFalse);
      expect(s.reminders, isTrue);
      expect(s.news, isTrue);
    });

    test('roundtrip toJson/fromJson', () {
      const s = NotificationSettings(
        push: false,
        email: true,
        sms: true,
        reminders: false,
        news: true,
      );
      final back = NotificationSettings.fromJson(s.toJson());
      expect(back.push, s.push);
      expect(back.email, s.email);
      expect(back.sms, s.sms);
      expect(back.reminders, s.reminders);
      expect(back.news, s.news);
    });

    test('copyWith меняет только указанное', () {
      const s = NotificationSettings();
      final n = s.copyWith(reminders: false);
      expect(n.reminders, isFalse);
      expect(n.push, isTrue);
    });
  });
}
