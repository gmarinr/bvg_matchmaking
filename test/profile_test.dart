import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el perfil muestra y permite editar datos deportivos', (
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

    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();

    expect(find.text('Tu perfil deportivo'), findsOneWidget);
    expect(find.text('Tu ID'), findsOneWidget);
    expect(find.text('fake-user-1'), findsOneWidget);
    expect(find.text('Disponibilidad general'), findsOneWidget);
    expect(
      find.text('Deportes y niveles', skipOffstage: false),
      findsOneWidget,
    );

    final copyButton = find.byTooltip('Copiar ID');
    await tester.ensureVisible(copyButton);
    await tester.tap(copyButton);
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField).first;
    await tester.ensureVisible(nameField);
    await tester.enterText(nameField, 'Jugador actualizado');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Perfil actualizado.'), findsOneWidget);
  });
}
