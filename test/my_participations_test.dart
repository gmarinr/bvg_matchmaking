import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Mis partidos muestra el partido y el estado de participación', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'jugador@test.cl');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesiÃ³n'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    await tester.tap(find.text('Mis partidos'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    expect(find.text('VÃ³leibol en MaipÃº'), findsOneWidget);
    expect(
      find.text('Solicitud de participaciÃ³n: Aceptado'),
      findsOneWidget,
    );
    await tester.tap(find.textContaining('Maip'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.text('Detalle del partido'), findsOneWidget);
  });
}
