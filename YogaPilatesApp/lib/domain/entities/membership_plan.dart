import 'enums.dart';

/// Тариф абонемента (то, что можно купить).
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.name,
    required this.kind,
    required this.price,
    this.classesCount,
    this.durationDays,
  });

  final String id;
  final String name;
  final MembershipKind kind;
  final double price;
  final int? classesCount;
  final int? durationDays;

  /// Краткое описание тарифа для UI.
  String get summary {
    final parts = <String>[];
    if (kind.isCountBased && classesCount != null) {
      parts.add('$classesCount занятий');
    } else if (kind == MembershipKind.unlimited) {
      parts.add('Безлимит');
    }
    if (durationDays != null) parts.add('на $durationDays дн.');
    return parts.join(' · ');
  }
}
