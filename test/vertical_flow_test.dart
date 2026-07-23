import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('un usuario autenticado puede ver partidos y solicitar un cupo', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'jugador@test.cl');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
    expect(find.text('Solicitar participación'), findsWidgets);

    await tester.tap(find.text('Solicitar participación').first);
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Solicitud enviada.'), findsOneWidget);
  });
}
