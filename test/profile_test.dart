import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('el perfil muestra y permite editar datos deportivos', (
    tester,
  ) async {
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
    expect(find.text('Deportes y niveles'), findsOneWidget);

    await tester.tap(find.byTooltip('Copiar ID'));
    await tester.pump();
    expect(find.text('ID copiado al portapapeles.'), findsOneWidget);

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'Jugador actualizado',
    );
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    expect(find.text('Perfil actualizado.'), findsOneWidget);
  });
}
