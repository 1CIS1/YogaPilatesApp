/// Настройки уведомлений (хранятся в profiles.notify_prefs).
class NotificationSettings {
  const NotificationSettings({
    this.push = true,
    this.email = true,
    this.sms = false,
    this.reminders = true,
    this.news = true,
  });

  final bool push;
  final bool email;
  final bool sms;
  final bool reminders; // напоминания о занятиях
  final bool news; // новости и акции

  NotificationSettings copyWith({
    bool? push,
    bool? email,
    bool? sms,
    bool? reminders,
    bool? news,
  }) =>
      NotificationSettings(
        push: push ?? this.push,
        email: email ?? this.email,
        sms: sms ?? this.sms,
        reminders: reminders ?? this.reminders,
        news: news ?? this.news,
      );

  Map<String, dynamic> toJson() => {
        'push': push,
        'email': email,
        'sms': sms,
        'reminders': reminders,
        'news': news,
      };

  factory NotificationSettings.fromJson(Map<String, dynamic>? j) {
    final m = j ?? const {};
    return NotificationSettings(
      push: m['push'] as bool? ?? true,
      email: m['email'] as bool? ?? true,
      sms: m['sms'] as bool? ?? false,
      reminders: m['reminders'] as bool? ?? true,
      news: m['news'] as bool? ?? true,
    );
  }
}
