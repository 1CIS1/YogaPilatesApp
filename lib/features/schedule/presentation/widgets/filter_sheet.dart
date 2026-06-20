import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/entities/enums.dart';
import '../providers/schedule_providers.dart';

/// Открывает шторку фильтров расписания.
Future<void> showScheduleFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const FilterSheet(),
  );
}

class FilterSheet extends ConsumerWidget {
  const FilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filters = ref.watch(scheduleFiltersProvider);
    final notifier = ref.read(scheduleFiltersProvider.notifier);
    final typesAsync = ref.watch(classTypesProvider);
    final instructorsAsync = ref.watch(instructorsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 0, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Фильтры', style: theme.textTheme.titleLarge),
                const Spacer(),
                if (!filters.isEmpty)
                  TextButton(
                    onPressed: notifier.clear,
                    child: const Text('Очистить'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // --- Тип занятия ---
            Text('Тип занятия', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            typesAsync.when(
              data: (types) => Wrap(
                spacing: 8,
                children: [
                  for (final t in types)
                    ChoiceChip(
                      label: Text(t.name),
                      selected: filters.classTypeId == t.id,
                      onSelected: (sel) =>
                          notifier.setClassType(sel ? t.id : null),
                    ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Не удалось загрузить типы'),
            ),
            const SizedBox(height: 16),

            // --- Сложность ---
            Text('Сложность', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final d in DifficultyLevel.values)
                  ChoiceChip(
                    label: Text(d.label),
                    selected: filters.difficulty == d,
                    onSelected: (sel) =>
                        notifier.setDifficulty(sel ? d : null),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Преподаватель ---
            Text('Преподаватель', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            instructorsAsync.when(
              data: (instructors) => Wrap(
                spacing: 8,
                children: [
                  for (final i in instructors)
                    ChoiceChip(
                      label: Text(i.fullName),
                      selected: filters.instructorId == i.id,
                      onSelected: (sel) =>
                          notifier.setInstructor(sel ? i.id : null),
                    ),
                ],
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Не удалось загрузить преподавателей'),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Показать'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
