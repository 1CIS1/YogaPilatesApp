import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/enums.dart';
import '../../../../domain/entities/scheduled_class.dart';

/// Карточка занятия в списке расписания.
class ClassCard extends StatelessWidget {
  const ClassCard({super.key, required this.item, required this.onTap});

  final ScheduledClass item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFmt = DateFormat('HH:mm');
    final time =
        '${timeFmt.format(item.startsAt)}–${timeFmt.format(item.endsAt)}';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: _typeColor(theme),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.classType.name,
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '$time · ${item.difficulty.label}'
                      '${item.instructor != null ? ' · ${item.instructor!.fullName}' : ''}',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    _statusLine(theme),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(ThemeData theme) {
    if (item.isBooked) {
      return _chip(theme, 'Вы записаны', Icons.check_circle, theme.colorScheme.primary);
    }
    if (item.isWaitlisted) {
      return _chip(theme, 'В очереди: ${item.myWaitlistPosition}',
          Icons.hourglass_bottom, AppAvailabilityColors.warning);
    }
    final a = item.availability;
    return _chip(theme, _availabilityWithCount(a), _availabilityIcon(a),
        _availabilityColor(a));
  }

  String _availabilityWithCount(ClassAvailability a) {
    if (a == ClassAvailability.available || a == ClassAvailability.fewSpots) {
      return '${a.label} (${item.spotsLeft})';
    }
    return a.label;
  }

  Widget _chip(ThemeData theme, String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(text,
              style: theme.textTheme.labelMedium?.copyWith(color: color)),
        ],
      ),
    );
  }

  Color _typeColor(ThemeData theme) {
    final hex = item.classType.color;
    if (hex == null) return theme.colorScheme.primary;
    final parsed = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    if (parsed == null) return theme.colorScheme.primary;
    return Color(0xFF000000 | parsed);
  }

  Color _availabilityColor(ClassAvailability a) => switch (a) {
        ClassAvailability.available => AppAvailabilityColors.success,
        ClassAvailability.fewSpots => AppAvailabilityColors.warning,
        ClassAvailability.full => AppAvailabilityColors.danger,
        ClassAvailability.cancelled => AppAvailabilityColors.muted,
      };

  IconData _availabilityIcon(ClassAvailability a) => switch (a) {
        ClassAvailability.available => Icons.event_available,
        ClassAvailability.fewSpots => Icons.timelapse,
        ClassAvailability.full => Icons.block,
        ClassAvailability.cancelled => Icons.cancel,
      };
}

/// Цвета статусов доступности.
class AppAvailabilityColors {
  AppAvailabilityColors._();
  static const success = Color(0xFF34A853);
  static const warning = Color(0xFFF9AB00);
  static const danger = Color(0xFFD93025);
  static const muted = Color(0xFF9E9E9E);
}
