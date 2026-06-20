import 'enums.dart';

/// Позиция клиента в листе ожидания.
class WaitlistEntry {
  const WaitlistEntry({
    required this.id,
    required this.scheduledClassId,
    required this.position,
    required this.status,
  });

  final String id;
  final String scheduledClassId;
  final int position;
  final WaitlistStatus status;
}
