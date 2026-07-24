import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('envía una solicitud de amistad desde un perfil encontrado', (
    tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'jugador@test.cl',
    );
    await tester.enterText(find.byType(TextFormField).at(1), '123456');
    await tester.tap(find.text('Iniciar sesión'));
    await tester.pumpAndSettle(const Duration(milliseconds: 700));

    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      '11111111-1111-4111-8111-111111111111',
    );
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle(const Duration(milliseconds: 400));

    expect(find.text('Enviar solicitud'), findsOneWidget);
    await tester.tap(find.text('Enviar solicitud'));
    await tester.pumpAndSettle(const Duration(milliseconds: 800));

    expect(find.text('Solicitud de amistad enviada.'), findsOneWidget);
    expect(find.text('Solicitud enviada'), findsOneWidget);
  });
}
