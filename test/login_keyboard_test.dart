import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Enter en contraseña ejecuta el login una sola vez', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'jugador@test.cl');
    await tester.enterText(fields.at(1), '123456');
    await tester.showKeyboard(fields.at(1));
    tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.pumpAndSettle(const Duration(milliseconds: 700));
    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
  });
}
