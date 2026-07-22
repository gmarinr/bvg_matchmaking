import 'package:bvg_matchmaking/app/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('arranca en la pantalla de inicio de sesión', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MatchMakingApp()),
    );
    await tester.pumpAndSettle();

    // Sin sesión, el guard del router redirige a login.
    expect(find.text('Match Making'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}
