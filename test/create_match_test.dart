import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/data/matches_providers.dart';
import 'package:bvg_matchmaking/features/matches/presentation/create_match_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sesión ya iniciada, sin delays: en `testWidgets` el reloj es simulado y un
/// `await` fuera de un `pump` nunca completaría.
class _SignedInAuthRepository implements AuthRepository {
  static const user = AppUser(id: 'fake-user-1', email: 'org@test.cl');

  @override
  AppUser? get currentUser => user;

  @override
  Stream<AppUser?> authStateChanges() => const Stream<AppUser?>.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

/// Avanza el reloj simulado sin usar pumpAndSettle (los indicadores de
/// progreso animan indefinidamente y nunca se estabilizan).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets(
    'crear partido publica y queda como partido organizado',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_SignedInAuthRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CreateMatchPage()),
        ),
      );
      await _settle(tester); // catálogo de deportes

      await tester.tap(find.widgetWithText(ChoiceChip, 'Fútbol'));
      await tester.pump();

      // Orden de los TextField: título, descripción, comuna, lugar.
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'Fútbol de prueba');
      await tester.enterText(fields.at(2), 'Ñuñoa');
      await tester.enterText(fields.at(3), 'Estadio Nacional');
      await tester.pump();

      // Calendario -> OK, luego selector de hora -> OK (valores iniciales).
      await tester.tap(find.text('Selecciona fecha y hora'));
      await _settle(tester);
      await tester.tap(find.text('OK'));
      await _settle(tester);
      await tester.tap(find.text('OK'));
      await _settle(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Publicar partido'));
      await _settle(tester);

      // runAsync ejecuta fuera del reloj simulado para poder esperar el fake.
      final mine = await tester.runAsync(
        () => container
            .read(matchRepositoryProvider)
            .getMyOrganizedMatches('fake-user-1'),
      );

      expect(mine, hasLength(1));
      expect(mine!.first.title, 'Fútbol de prueba');
      expect(mine.first.commune, 'Ñuñoa');
      expect(mine.first.locationText, 'Estadio Nacional');
      // El organizador cuenta como participante.
      expect(mine.first.acceptedCount, 1);
    },
    timeout: const Timeout(Duration(seconds: 45)),
  );
}
