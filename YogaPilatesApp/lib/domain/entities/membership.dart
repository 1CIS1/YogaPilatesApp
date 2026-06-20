import 'enums.dart';

/// Купленный клиентом абонемент.
class Membership {
  const Membership({
    required this.id,
    required this.planName,
    required this.kind,
    required this.status,
    this.classesTotal,
    this.classesLeft,
    this.validFrom,
    this.validUntil,
  });

  final String id;
  final String planName;
  final MembershipKind kind;
  final MembershipStatus status;
  final int? classesTotal;
  final int? classesLeft;
  final DateTime? validFrom;
  final DateTime? validUntil;

  /// Доля использованных занятий (0..1) — для прогресс-бара.
  double? get usageProgress {
    if (!kind.isCountBased) return null;
    if (classesTotal == null || classesTotal == 0) return null;
    final used = (classesTotal! - (classesLeft ?? 0)).clamp(0, classesTotal!);
    return used / classesTotal!;
  }
}
