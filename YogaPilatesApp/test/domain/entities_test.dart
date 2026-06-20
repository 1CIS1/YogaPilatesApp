import 'package:flutter_test/flutter_test.dart';
import 'package:yoga_pilates_app/domain/entities/class_type.dart';
import 'package:yoga_pilates_app/domain/entities/enums.dart';
import 'package:yoga_pilates_app/domain/entities/membership.dart';
import 'package:yoga_pilates_app/domain/entities/membership_plan.dart';
import 'package:yoga_pilates_app/domain/entities/scheduled_class.dart';

ScheduledClass _cls({
  required int capacity,
  required int booked,
  ClassStatus status = ClassStatus.scheduled,
}) {
  final now = DateTime(2026, 6, 20, 10);
  return ScheduledClass(
    id: 'c1',
    classType: const ClassType(id: 't1', name: 'Йога'),
    startsAt: now,
    endsAt: now.add(const Duration(hours: 1)),
    capacity: capacity,
    bookedCount: booked,
    difficulty: DifficultyLevel.beginner,
    status: status,
    price: 800,
  );
}

void main() {
  group('ScheduledClass.availability', () {
    test('есть места', () {
      final c = _cls(capacity: 10, booked: 2);
      expect(c.spotsLeft, 8);
      expect(c.availability, ClassAvailability.available);
    });

    test('мест мало (<=3)', () {
      expect(_cls(capacity: 10, booked: 8).availability,
          ClassAvailability.fewSpots);
    });

    test('занято', () {
      final c = _cls(capacity: 5, booked: 5);
      expect(c.spotsLeft, 0);
      expect(c.availability, ClassAvailability.full);
    });

    test('отменено имеет приоритет', () {
      final c = _cls(capacity: 10, booked: 0, status: ClassStatus.cancelled);
      expect(c.availability, ClassAvailability.cancelled);
    });
  });

  group('Membership.usageProgress', () {
    test('поштучный считает долю использованных', () {
      const m = Membership(
        id: 'm1',
        planName: '8 занятий',
        kind: MembershipKind.countBased,
        status: MembershipStatus.active,
        classesTotal: 8,
        classesLeft: 6,
      );
      expect(m.usageProgress, closeTo(0.25, 0.0001));
    });

    test('безлимит → null', () {
      const m = Membership(
        id: 'm2',
        planName: 'Безлимит',
        kind: MembershipKind.unlimited,
        status: MembershipStatus.active,
      );
      expect(m.usageProgress, isNull);
    });
  });

  group('MembershipPlan.summary', () {
    test('поштучный с длительностью', () {
      const p = MembershipPlan(
        id: 'p1',
        name: 'Абонемент 8',
        kind: MembershipKind.countBased,
        price: 7000,
        classesCount: 8,
        durationDays: 30,
      );
      expect(p.summary, contains('8 занятий'));
      expect(p.summary, contains('30'));
    });

    test('безлимит', () {
      const p = MembershipPlan(
        id: 'p2',
        name: 'Безлимит',
        kind: MembershipKind.unlimited,
        price: 12000,
        durationDays: 30,
      );
      expect(p.summary, contains('Безлимит'));
    });
  });
}
