import 'package:flutter_test/flutter_test.dart';
import 'package:yoga_pilates_app/domain/entities/enums.dart';

void main() {
  group('DifficultyLevel', () {
    test('fromDb распознаёт значения', () {
      expect(DifficultyLevel.fromDb('beginner'), DifficultyLevel.beginner);
      expect(
          DifficultyLevel.fromDb('intermediate'), DifficultyLevel.intermediate);
      expect(DifficultyLevel.fromDb('advanced'), DifficultyLevel.advanced);
      expect(DifficultyLevel.fromDb(null), DifficultyLevel.beginner);
      expect(DifficultyLevel.fromDb('xxx'), DifficultyLevel.beginner);
    });

    test('dbValue и label заполнены', () {
      for (final d in DifficultyLevel.values) {
        expect(d.dbValue, isNotEmpty);
        expect(d.label, isNotEmpty);
      }
    });
  });

  group('BookingStatus', () {
    test('fromDb и isCancelled', () {
      expect(BookingStatus.fromDb('cancelled_by_client').isCancelled, isTrue);
      expect(BookingStatus.fromDb('cancelled_by_admin').isCancelled, isTrue);
      expect(BookingStatus.fromDb('booked').isCancelled, isFalse);
      expect(BookingStatus.fromDb('attended'), BookingStatus.attended);
    });
  });

  group('MembershipKind / Status', () {
    test('kind mapping', () {
      expect(MembershipKind.fromDb('unlimited'), MembershipKind.unlimited);
      expect(MembershipKind.fromDb('count_based').isCountBased, isTrue);
      expect(MembershipKind.fromDb('package').isCountBased, isTrue);
      expect(MembershipKind.fromDb('unlimited').isCountBased, isFalse);
    });

    test('status mapping', () {
      expect(MembershipStatus.fromDb('active').isActive, isTrue);
      expect(MembershipStatus.fromDb('used_up'), MembershipStatus.usedUp);
      expect(MembershipStatus.fromDb('expired').isActive, isFalse);
    });
  });

  group('PurchaseType / PaymentStatus', () {
    test('purchase type roundtrip', () {
      expect(PurchaseType.membership.dbValue, 'membership');
      expect(PurchaseType.singleClass.dbValue, 'single_class');
      expect(PurchaseType.fromDb('single_class'), PurchaseType.singleClass);
    });

    test('payment status', () {
      expect(PaymentStatus.fromDb('succeeded').isSuccess, isTrue);
      expect(PaymentStatus.fromDb('pending').isSuccess, isFalse);
      expect(PaymentStatus.fromDb(null), PaymentStatus.pending);
    });
  });
}
