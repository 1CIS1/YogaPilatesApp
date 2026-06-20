import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../domain/entities/admin_entities.dart';
import '../../../../domain/entities/enums.dart';
import '../../../schedule/presentation/providers/schedule_providers.dart';
import '../providers/admin_providers.dart';

/// Создание/редактирование занятия.
class AdminClassFormScreen extends ConsumerStatefulWidget {
  const AdminClassFormScreen({super.key, this.editing});

  final AdminClass? editing;

  @override
  ConsumerState<AdminClassFormScreen> createState() =>
      _AdminClassFormScreenState();
}

class _AdminClassFormScreenState extends ConsumerState<AdminClassFormScreen> {
  String? _typeId;
  String? _instructorId;
  String? _hallId;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  DifficultyLevel _difficulty = DifficultyLevel.beginner;
  final _capacityCtrl = TextEditingController(text: '10');
  final _priceCtrl = TextEditingController(text: '0');
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final e = widget.editing;
    if (e != null) {
      _typeId = e.classTypeId;
      _instructorId = e.instructorId;
      _hallId = e.hallId;
      _date = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      _start = TimeOfDay.fromDateTime(e.startsAt);
      _end = TimeOfDay.fromDateTime(e.endsAt);
      _difficulty = e.difficulty;
      _capacityCtrl.text = '${e.capacity}';
      _priceCtrl.text = e.price.toStringAsFixed(0);
    } else {
      final n = DateTime.now();
      _date = DateTime(n.year, n.month, n.day);
      _start = const TimeOfDay(hour: 10, minute: 0);
      _end = const TimeOfDay(hour: 11, minute: 0);
    }
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  DateTime _combine(TimeOfDay t) =>
      DateTime(_date.year, _date.month, _date.day, t.hour, t.minute);

  Future<void> _save() async {
    if (_typeId == null) {
      _snack('Выберите тип занятия');
      return;
    }
    final startsAt = _combine(_start);
    final endsAt = _combine(_end);
    if (!endsAt.isAfter(startsAt)) {
      _snack('Время окончания должно быть позже начала');
      return;
    }
    final capacity = int.tryParse(_capacityCtrl.text) ?? 0;
    if (capacity <= 0) {
      _snack('Укажите лимит мест');
      return;
    }
    final price = double.tryParse(_priceCtrl.text.replaceAll(',', '.')) ?? 0;

    setState(() => _busy = true);
    try {
      final ctrl = ref.read(adminControllerProvider.notifier);
      if (widget.editing == null) {
        await ctrl.createClass(
          classTypeId: _typeId!,
          instructorId: _instructorId,
          hallId: _hallId,
          startsAt: startsAt,
          endsAt: endsAt,
          capacity: capacity,
          difficulty: _difficulty,
          price: price,
        );
      } else {
        await ctrl.updateClass(
          id: widget.editing!.id,
          classTypeId: _typeId!,
          instructorId: _instructorId,
          hallId: _hallId,
          startsAt: startsAt,
          endsAt: endsAt,
          capacity: capacity,
          difficulty: _difficulty,
          price: price,
        );
      }
      if (mounted) {
        _snack('Сохранено');
        context.pop();
      }
    } catch (e) {
      if (mounted) _snack('Ошибка: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(classTypesProvider);
    final instructorsAsync = ref.watch(instructorsProvider);
    final hallsAsync = ref.watch(adminHallsProvider);
    final isEdit = widget.editing != null;

    return Scaffold(
      appBar: AppBar(
          title: Text(isEdit ? 'Редактирование занятия' : 'Новое занятие')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          typesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Не удалось загрузить типы'),
            data: (types) => DropdownButtonFormField<String>(
              value: _typeId,
              decoration: const InputDecoration(labelText: 'Тип занятия'),
              items: [
                for (final t in types)
                  DropdownMenuItem(value: t.id, child: Text(t.name)),
              ],
              onChanged: (v) => setState(() => _typeId = v),
            ),
          ),
          const SizedBox(height: 12),
          instructorsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Не удалось загрузить преподавателей'),
            data: (instructors) => DropdownButtonFormField<String>(
              value: _instructorId,
              decoration:
                  const InputDecoration(labelText: 'Преподаватель (необяз.)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Не назначен')),
                for (final i in instructors)
                  DropdownMenuItem(value: i.id, child: Text(i.fullName)),
              ],
              onChanged: (v) => setState(() => _instructorId = v),
            ),
          ),
          const SizedBox(height: 12),
          hallsAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => const Text('Не удалось загрузить залы'),
            data: (halls) => DropdownButtonFormField<String>(
              value: _hallId,
              decoration: const InputDecoration(labelText: 'Зал (необяз.)'),
              items: [
                const DropdownMenuItem(value: null, child: Text('Не выбран')),
                for (final h in halls)
                  DropdownMenuItem(value: h.id, child: Text(h.name)),
              ],
              onChanged: (v) => setState(() => _hallId = v),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text('Дата: ${DateFormat('dd.MM.yyyy').format(_date)}'),
            trailing: const Icon(Icons.edit),
            onTap: _pickDate,
          ),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Начало: ${_start.format(context)}'),
                  onTap: () => _pickTime(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Конец: ${_end.format(context)}'),
                  onTap: () => _pickTime(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Сложность'),
          const SizedBox(height: 6),
          SegmentedButton<DifficultyLevel>(
            segments: [
              for (final d in DifficultyLevel.values)
                ButtonSegment(value: d, label: Text(d.label)),
            ],
            selected: {_difficulty},
            onSelectionChanged: (s) => setState(() => _difficulty = s.first),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _capacityCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Лимит мест'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Цена разового, ₽'),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _busy ? null : _save,
            style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52)),
            child: Text(_busy ? 'Сохранение…' : 'Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2023),
      lastDate: DateTime(2031),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime(bool start) async {
    final picked = await showTimePicker(
        context: context, initialTime: start ? _start : _end);
    if (picked != null) {
      setState(() {
        if (start) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }
}
