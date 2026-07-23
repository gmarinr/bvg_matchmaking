import 'package:bvg_matchmaking/features/matches/presentation/matches_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta la lista en una superficie tamaño teléfono y espera a que los
/// repositorios falsos resuelvan sus delays simulados.
Future<void> _pumpList(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    const ProviderScope(
      child: MaterialApp(home: Scaffold(body: MatchesListPage())),
    ),
  );
  await tester.pump(); // primer frame (estado de carga)
  await tester.pump(const Duration(milliseconds: 500)); // resuelven los fakes
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('la lista muestra los partidos semilla', (tester) async {
    await _pumpList(tester);

    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
    expect(find.text('Básquet 3x3 nocturno'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
  });

  testWidgets('filtrar por deporte reduce la lista', (tester) async {
    await _pumpList(tester);

    // "Fútbol" es de los primeros chips (visible sin scroll horizontal).
    await tester.tap(find.widgetWithText(FilterChip, 'Fútbol'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
    expect(find.text('Básquet 3x3 nocturno'), findsNothing);
  });
}
