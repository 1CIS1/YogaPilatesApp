import '../../domain/entities/enums.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/my_schedule_item.dart';

/// Преобразование строк RPC личного кабинета в доменные сущности.
class AccountMappers {
  AccountMappers._();

  static MyScheduleItem scheduleItemFromRow(Map<String, dynamic> r) {
    return MyScheduleItem(
      itemId: r['item_id'] as String,
      kind: (r['kind'] == 'waitlist')
          ? MyItemKind.waitlist
          : MyItemKind.booking,
      scheduledClassId: r['scheduled_class_id'] as String,
      startsAt: DateTime.parse(r['starts_at'] as String).toLocal(),
      endsAt: DateTime.parse(r['ends_at'] as String).toLocal(),
      classTypeName: (r['class_type_name'] as String?) ?? '',
      classTypeColor: r['class_type_color'] as String?,
      instructorName: r['instructor_name'] as String?,
      hallName: r['hall_name'] as String?,
      bookingStatus: r['booking_status'] == null
          ? null
          : BookingStatus.fromDb(r['booking_status'] as String?),
      waitlistPosition: (r['waitlist_position'] as num?)?.toInt(),
      isPast: (r['is_past'] as bool?) ?? false,
    );
  }

  static Membership membershipFromRow(Map<String, dynamic> r) {
    return Membership(
      id: r['id'] as String,
      planName: (r['plan_name'] as String?) ?? '',
      kind: MembershipKind.fromDb(r['kind'] as String?),
      status: MembershipStatus.fromDb(r['status'] as String?),
      classesTotal: (r['classes_total'] as num?)?.toInt(),
      classesLeft: (r['classes_left'] as num?)?.toInt(),
      validFrom: r['valid_from'] == null
          ? null
          : DateTime.parse(r['valid_from'] as String),
      validUntil: r['valid_until'] == null
          ? null
          : DateTime.parse(r['valid_until'] as String),
    );
  }
}
