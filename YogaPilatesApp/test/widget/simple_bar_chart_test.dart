import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yoga_pilates_app/features/admin/presentation/widgets/simple_bar_chart.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('SimpleBarChart показывает подписи столбцов', (tester) async {
    await tester.pumpWidget(_wrap(const SimpleBarChart(
      data: [
        BarDatum('01.06', 10),
        BarDatum('02.06', 20),
      ],
    )));

    expect(find.text('01.06'), findsOneWidget);
    expect(find.text('02.06'), findsOneWidget);
  });

  testWidgets('SimpleBarChart показывает заглушку для пустых данных',
      (tester) async {
    await tester.pumpWidget(_wrap(const SimpleBarChart(data: [])));
    expect(find.text('Нет данных за период'), findsOneWidget);
  });
}
