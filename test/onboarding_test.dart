import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('una cuenta nueva debe completar el onboarding', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextButton));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'nuevo@test.cl');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    expect(find.text('Completa tu perfil'), findsOneWidget);
    expect(find.text('Guardar y continuar'), findsOneWidget);
  });
}
