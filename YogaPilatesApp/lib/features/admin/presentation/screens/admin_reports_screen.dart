import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/loading_indicator.dart';
import '../../../../domain/entities/admin_entities.dart';
import '../providers/admin_providers.dart';
import '../widgets/simple_bar_chart.dart';

/// Простые отчёты: продажи и посещаемость за 14 дней.
class AdminReportsScreen extends ConsumerWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final salesAsync = ref.watch(salesReportProvider);
    final attendanceAsync = ref.watch(attendanceReportProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Отчёты')),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(salesReportProvider);
          ref.invalidate(attendanceReportProvider);
          await ref.read(salesReportProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _reportCard(
              context,
              title: 'Продажи, ₽ (14 дней)',
              async: salesAsync,
            ),
            const SizedBox(height: 16),
            _reportCard(
              context,
              title: 'Посещаемость (14 дней)',
              async: attendanceAsync,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(
    BuildContext context, {
    required String title,
    required AsyncValue<List<ReportPoint>> async,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            async.when(
              loading: () => const SizedBox(
                  height: 160, child: Center(child: CircularProgressIndicator())),
              error: (_, __) =>
                  const SizedBox(height: 160, child: Center(child: Text('—'))),
              data: (points) {
                final fmt = DateFormat('d.MM');
                final data = [
                  for (final p in points)
                    BarDatum(fmt.format(p.day), p.value),
                ];
                return Column(
                  children: [
                    SimpleBarChart(data: data),
                    const SizedBox(height: 8),
                    Text(
                      'Итого: ${_total(points)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _total(List<ReportPoint> points) {
    final sum = points.fold<double>(0, (a, p) => a + p.value);
    return sum.toStringAsFixed(0);
  }
}
