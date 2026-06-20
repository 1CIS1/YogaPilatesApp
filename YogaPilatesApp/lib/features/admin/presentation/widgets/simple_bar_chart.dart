import 'package:flutter/material.dart';

class BarDatum {
  const BarDatum(this.label, this.value);
  final String label;
  final double value;
}

/// Лёгкий столбчатый график без внешних зависимостей.
class SimpleBarChart extends StatelessWidget {
  const SimpleBarChart({super.key, required this.data, this.height = 160});

  final List<BarDatum> data;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (data.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(child: Text('Нет данных за период')),
      );
    }
    final maxVal = data.map((d) => d.value).fold<double>(0, (a, b) => b > a ? b : a);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      d.value == 0 ? '' : _fmt(d.value),
                      style: const TextStyle(fontSize: 9),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      height: maxVal <= 0 ? 2 : (height - 50) * (d.value / maxVal) + 2,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(d.label,
                        style: const TextStyle(fontSize: 9),
                        maxLines: 1,
                        overflow: TextOverflow.clip),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.toStringAsFixed(0);
  }
}
