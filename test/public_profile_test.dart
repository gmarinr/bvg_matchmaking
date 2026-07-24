import 'package:bvg_matchmaking/features/users/data/fake_user_search_repository.dart';
import 'package:bvg_matchmaking/features/users/presentation/public_profile_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Avanza el reloj simulado para dejar resolver el fake (300 ms) sin
/// pumpAndSettle, que no se estabiliza con los indicadores de progreso.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('el perfil público muestra usuario, comuna y deportes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PublicProfilePage(userId: FakeUserSearchRepository.demoUserId),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('Camila Rojas'), findsOneWidget); // usuario
    expect(find.text('La Reina'), findsOneWidget); // comuna
    expect(find.text('Fútbol'), findsOneWidget); // deporte
    expect(find.text('Tenis'), findsOneWidget); // deporte
  });

  testWidgets('un id sin perfil muestra el estado vacío', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: PublicProfilePage(userId: 'no-existe'),
        ),
      ),
    );
    await _settle(tester);

    expect(find.text('No encontramos este perfil.'), findsOneWidget);
  });
}
