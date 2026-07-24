import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('envía una solicitud de amistad desde un perfil encontrado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'jugador@test.cl');
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    await tester.tap(find.text('Buscar').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      '11111111-1111-4111-8111-111111111111',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Buscar'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Enviar solicitud'), findsOneWidget);
    final sendButton = find.widgetWithText(FilledButton, 'Enviar solicitud');
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    expect(find.text('Solicitud de amistad enviada.'), findsOneWidget);
    expect(find.text('Solicitud enviada'), findsOneWidget);
  });
}
