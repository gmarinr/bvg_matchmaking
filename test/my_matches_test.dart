import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/presentation/my_matches_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Sesión ya iniciada con el id indicado, sin delays: en `testWidgets` el
/// reloj es simulado y un `await` fuera de un `pump` nunca completaría.
class _SignedInAuthRepository implements AuthRepository {
  _SignedInAuthRepository(this.userId);

  final String userId;

  @override
  AppUser? get currentUser => AppUser(id: userId, email: '$userId@test.cl');

  @override
  Stream<AppUser?> authStateChanges() => const Stream<AppUser?>.empty();

  @override
  Future<void> signIn({required String email, required String password}) async {}

  @override
  Future<void> signUp({required String email, required String password}) async {}

  @override
  Future<void> signOut() async {}
}

/// Avanza el reloj simulado sin usar pumpAndSettle. Las cargas están
/// encadenadas (participaciones y luego el partido de cada una), así que
/// hacen falta varios avances.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _pumpMyMatches(
  WidgetTester tester, {
  required String userId,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_SignedInAuthRepository(userId)),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: MyMatchesPage())),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('la pestaña Organizo lista los partidos propios',
      (tester) async {
    // m4 lo organiza fake-user-1.
    await _pumpMyMatches(tester, userId: 'fake-user-1');

    expect(find.text('Vóleibol en Maipú'), findsOneWidget);
    expect(find.textContaining('Faltan 2'), findsOneWidget);
  });

  testWidgets('sin partidos organizados se muestra el estado vacío',
      (tester) async {
    await _pumpMyMatches(tester, userId: 'user-a');

    expect(find.text('Aún no organizas ningún partido'), findsOneWidget);
  });

  testWidgets('la pestaña Participo muestra el estado de mi solicitud',
      (tester) async {
    // user-a tiene una solicitud pendiente en m4.
    await _pumpMyMatches(tester, userId: 'user-a');

    await tester.tap(find.text('Participo'));
    await _settle(tester);

    expect(find.text('Vóleibol en Maipú'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Esperando al organizador'), findsOneWidget);
  });

  testWidgets('las participaciones como organizador no se duplican',
      (tester) async {
    // fake-user-1 es organizador de m4: no debe aparecer en "Participo".
    await _pumpMyMatches(tester, userId: 'fake-user-1');

    await tester.tap(find.text('Participo'));
    await _settle(tester);

    expect(
      find.text('Todavía no participas en ningún partido'),
      findsOneWidget,
    );
  });
}
