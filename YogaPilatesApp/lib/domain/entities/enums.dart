/// Уровень сложности занятия (синхронизировано с enum difficulty_level в БД).
enum DifficultyLevel {
  beginner,
  intermediate,
  advanced;

  String get dbValue => switch (this) {
        DifficultyLevel.beginner => 'beginner',
        DifficultyLevel.intermediate => 'intermediate',
        DifficultyLevel.advanced => 'advanced',
      };

  String get label => switch (this) {
        DifficultyLevel.beginner => 'Новичок',
        DifficultyLevel.intermediate => 'Средний',
        DifficultyLevel.advanced => 'Продвинутый',
      };

  static DifficultyLevel fromDb(String? value) => switch (value) {
        'intermediate' => DifficultyLevel.intermediate,
        'advanced' => DifficultyLevel.advanced,
        _ => DifficultyLevel.beginner,
      };
}

/// Статус занятия (enum class_status в БД).
enum ClassStatus {
  scheduled,
  cancelled,
  completed;

  static ClassStatus fromDb(String? value) => switch (value) {
        'cancelled' => ClassStatus.cancelled,
        'completed' => ClassStatus.completed,
        _ => ClassStatus.scheduled,
      };
}

/// Производный статус доступности (для UI). Вычисляется из мест и статуса.
enum ClassAvailability {
  available, // есть места
  fewSpots, // мест мало
  full, // занято
  cancelled; // отменено

  String get label => switch (this) {
        ClassAvailability.available => 'Есть места',
        ClassAvailability.fewSpots => 'Мест мало',
        ClassAvailability.full => 'Занято',
        ClassAvailability.cancelled => 'Отменено',
      };
}

/// Статус записи (enum booking_status в БД).
enum BookingStatus {
  booked,
  attended,
  noShow,
  cancelledByClient,
  cancelledByAdmin;

  String get label => switch (this) {
        BookingStatus.booked => 'Записан',
        BookingStatus.attended => 'Посещено',
        BookingStatus.noShow => 'Пропущено',
        BookingStatus.cancelledByClient => 'Отменено',
        BookingStatus.cancelledByAdmin => 'Отменено студией',
      };

  bool get isCancelled =>
      this == BookingStatus.cancelledByClient ||
      this == BookingStatus.cancelledByAdmin;

  static BookingStatus fromDb(String? value) => switch (value) {
        'attended' => BookingStatus.attended,
        'no_show' => BookingStatus.noShow,
        'cancelled_by_client' => BookingStatus.cancelledByClient,
        'cancelled_by_admin' => BookingStatus.cancelledByAdmin,
        _ => BookingStatus.booked,
      };
}

/// Тип абонемента (enum membership_kind в БД).
enum MembershipKind {
  countBased,
  unlimited,
  timeRestricted,
  package;

  bool get isCountBased =>
      this == MembershipKind.countBased || this == MembershipKind.package;

  String get label => switch (this) {
        MembershipKind.countBased => 'По количеству занятий',
        MembershipKind.unlimited => 'Безлимит',
        MembershipKind.timeRestricted => 'С ограничением по времени',
        MembershipKind.package => 'Пакет занятий',
      };

  static MembershipKind fromDb(String? value) => switch (value) {
        'unlimited' => MembershipKind.unlimited,
        'time_restricted' => MembershipKind.timeRestricted,
        'package' => MembershipKind.package,
        _ => MembershipKind.countBased,
      };
}

/// Статус абонемента (enum membership_status в БД).
enum MembershipStatus {
  active,
  expired,
  frozen,
  usedUp;

  bool get isActive => this == MembershipStatus.active;

  String get label => switch (this) {
        MembershipStatus.active => 'Активен',
        MembershipStatus.expired => 'Истёк',
        MembershipStatus.frozen => 'Заморожен',
        MembershipStatus.usedUp => 'Использован',
      };

  static MembershipStatus fromDb(String? value) => switch (value) {
        'expired' => MembershipStatus.expired,
        'frozen' => MembershipStatus.frozen,
        'used_up' => MembershipStatus.usedUp,
        _ => MembershipStatus.active,
      };
}

/// Тип покупки (enum purchase_type в БД).
enum PurchaseType {
  singleClass,
  membership,
  package,
  giftCertificate;

  String get dbValue => switch (this) {
        PurchaseType.singleClass => 'single_class',
        PurchaseType.membership => 'membership',
        PurchaseType.package => 'package',
        PurchaseType.giftCertificate => 'gift_certificate',
      };

  static PurchaseType fromDb(String? value) => switch (value) {
        'membership' => PurchaseType.membership,
        'package' => PurchaseType.package,
        'gift_certificate' => PurchaseType.giftCertificate,
        _ => PurchaseType.singleClass,
      };
}

/// Статус платежа (enum payment_status в БД).
enum PaymentStatus {
  pending,
  succeeded,
  failed,
  refunded,
  partiallyRefunded;

  bool get isSuccess => this == PaymentStatus.succeeded;

  static PaymentStatus fromDb(String? value) => switch (value) {
        'succeeded' => PaymentStatus.succeeded,
        'failed' => PaymentStatus.failed,
        'refunded' => PaymentStatus.refunded,
        'partially_refunded' => PaymentStatus.partiallyRefunded,
        _ => PaymentStatus.pending,
      };
}

/// Статус позиции в листе ожидания (enum waitlist_status в БД).
enum WaitlistStatus {
  waiting,
  promoted,
  expired,
  cancelled;

  static WaitlistStatus fromDb(String? value) => switch (value) {
        'promoted' => WaitlistStatus.promoted,
        'expired' => WaitlistStatus.expired,
        'cancelled' => WaitlistStatus.cancelled,
        _ => WaitlistStatus.waiting,
      };
}
