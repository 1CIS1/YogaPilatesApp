import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/scheduled_class.dart';
import '../../../../domain/repositories/schedule_repository.dart';
import '../../../payments/presentation/providers/payment_providers.dart';
import '../providers/schedule_providers.dart';

/// Экран занятия: детали + запись / отмена / лист ожидания.
class ClassDetailsScreen extends ConsumerStatefulWidget {
  const ClassDetailsScreen({super.key, required this.item});

  final ScheduledClass item;

  @override
  ConsumerState<ClassDetailsScreen> createState() => _ClassDetailsScreenState();
}

class _ClassDetailsScreenState extends ConsumerState<ClassDetailsScreen> {
  bool _busy = false;
  late bool _isFullNow = widget.item.availability == ClassAvailability.full;

  ScheduledClass get item => widget.item;

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _book() => _run(() async {
        final outcome =
            await ref.read(bookingControllerProvider.notifier).book(item.id);
        if (!mounted) return;
        switch (outcome) {
          case BookingOutcome.booked:
            _snack('Вы записаны на занятие');
            context.pop();
          case BookingOutcome.alreadyBooked:
            _snack('Вы уже записаны');
            context.pop();
          case BookingOutcome.full:
            _snack('Мест нет. Можно встать в лист ожидания.');
            setState(() => _isFullNow = true);
        }
      });

  Future<void> _cancel() => _run(() async {
        await ref
            .read(bookingControllerProvider.notifier)
            .cancel(item.myBookingId!);
        if (!mounted) return;
        _snack('Запись отменена');
        context.pop();
      });

  Future<void> _joinWaitlist() => _run(() async {
        final position = await ref
            .read(bookingControllerProvider.notifier)
            .joinWaitlist(item.id);
        if (!mounted) return;
        _snack('Вы в листе ожидания, позиция $position');
        context.pop();
      });

  Future<void> _leaveWaitlist() => _run(() async {
        await ref
            .read(bookingControllerProvider.notifier)
            .leaveWaitlist(item.id);
        if (!mounted) return;
        _snack('Вы вышли из листа ожидания');
        context.pop();
      });

  bool get _canPaySingle =>
      !item.isBooked &&
      !item.isWaitlist &&
      !_isFullNow &&
      item.status == ClassStatus.scheduled &&
      item.price > 0;

  Future<void> _paySingle() async {
    final timeFmt = DateFormat('d MMM, HH:mm', 'ru_RU');
    final ok = await context.push<bool>(
      AppRoutes.checkout,
      extra: CheckoutArgs(
        type: PurchaseType.singleClass,
        relatedId: item.id,
        title: item.classType.name,
        subtitle: timeFmt.format(item.startsAt),
        price: item.price,
      ),
    );
    if (ok == true && mounted) {
      _snack('Оплачено, вы записаны');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('EEEE, d MMMM', 'ru_RU');
    final timeFmt = DateFormat('HH:mm');

    return Scaffold(
      appBar: AppBar(title: Text(item.classType.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(item.classType.name, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          _infoRow(Icons.calendar_today, dateFmt.format(item.startsAt)),
          _infoRow(Icons.access_time,
              '${timeFmt.format(item.startsAt)}–${timeFmt.format(item.endsAt)}'),
          _infoRow(Icons.signal_cellular_alt, item.difficulty.label),
          if (item.instructor != null)
            _infoRow(Icons.person_outline, item.instructor!.fullName),
          if (item.hallName != null)
            _infoRow(Icons.meeting_room_outlined, item.hallName!),
          _infoRow(
            Icons.event_seat,
            'Свободно мест: ${item.spotsLeft} из ${item.capacity}',
          ),
          if (item.price > 0)
            _infoRow(Icons.payments_outlined,
                'Разовое посещение: ${item.price.toStringAsFixed(0)} ₽'),
          const SizedBox(height: 24),
          _actionArea(theme),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _actionArea(ThemeData theme) {
    if (item.status == ClassStatus.cancelled) {
      return _notice('Занятие отменено', theme.colorScheme.error);
    }

    final Widget button;
    if (item.isBooked) {
      button = OutlinedButton.icon(
        onPressed: _busy ? null : _cancel,
        icon: const Icon(Icons.close),
        label: const Text('Отменить запись'),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: theme.colorScheme.error,
        ),
      );
    } else if (item.isWaitlisted) {
      return Column(
        children: [
          _notice('Вы в листе ожидания, позиция ${item.myWaitlistPosition}',
              theme.colorScheme.primary),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : _leaveWaitlist,
            style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: const Text('Выйти из листа ожидания'),
          ),
        ],
      );
    } else if (_isFullNow) {
      button = FilledButton.icon(
        onPressed: _busy ? null : _joinWaitlist,
        icon: const Icon(Icons.hourglass_bottom),
        label: const Text('В лист ожидания'),
      );
    } else {
      button = FilledButton.icon(
        onPressed: _busy ? null : _book,
        icon: const Icon(Icons.check),
        label: const Text('Записаться'),
      );
    }

    return Column(
      children: [
        if (_busy) const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LinearProgressIndicator(),
        ),
        SizedBox(width: double.infinity, child: button),
        if (_canPaySingle) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _paySingle,
              icon: const Icon(Icons.payments_outlined),
              label: Text(
                  'Оплатить разовое: ${item.price.toStringAsFixed(0)} ₽'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(52)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _notice(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(color: color)),
    );
  }
}
