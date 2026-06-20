import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/navigation/app_router.dart';
import '../../../../core/widgets/loading_indicator.dart';
import '../providers/schedule_providers.dart';
import '../widgets/class_card.dart';
import '../widgets/filter_sheet.dart';

/// Экран расписания: календарь + фильтры + список занятий на выбранный день.
class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _format = CalendarFormat.week;

  @override
  Widget build(BuildContext context) {
    final selectedDay = ref.watch(selectedDayProvider);
    final scheduleAsync = ref.watch(scheduleForDayProvider);
    final filters = ref.watch(scheduleFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        actions: [
          IconButton(
            tooltip: 'Фильтры',
            onPressed: () => showScheduleFilterSheet(context),
            icon: Badge.count(
              count: filters.activeCount,
              isLabelVisible: filters.activeCount > 0,
              child: const Icon(Icons.filter_list),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ru_RU',
            firstDay: DateTime.utc(2023, 1, 1),
            lastDay: DateTime.utc(2031, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _format,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {
              CalendarFormat.week: 'Неделя',
              CalendarFormat.month: 'Месяц',
            },
            selectedDayPredicate: (d) => isSameDay(selectedDay, d),
            onDaySelected: (selected, focused) {
              setState(() => _focusedDay = focused);
              ref.read(selectedDayProvider.notifier).select(selected);
            },
            onFormatChanged: (f) => setState(() => _format = f),
            onPageChanged: (focused) => _focusedDay = focused,
          ),
          const Divider(height: 1),
          Expanded(
            child: scheduleAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return const _EmptyState();
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(scheduleForDayProvider);
                    await ref.read(scheduleForDayProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: list.length,
                    itemBuilder: (context, i) {
                      final item = list[i];
                      return ClassCard(
                        item: item,
                        onTap: () =>
                            context.push(AppRoutes.classDetails, extra: item),
                      );
                    },
                  ),
                );
              },
              loading: () => const LoadingIndicator(),
              error: (e, _) => _ErrorState(
                onRetry: () => ref.invalidate(scheduleForDayProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      // ListView, чтобы работал pull-to-refresh даже на пустом списке.
      children: const [
        SizedBox(height: 80),
        Icon(Icons.event_busy, size: 56, color: Colors.grey),
        SizedBox(height: 12),
        Center(child: Text('На этот день занятий нет')),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('Не удалось загрузить расписание'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
