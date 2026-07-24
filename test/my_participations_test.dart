import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/presentation/my_participations_page.dart';
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

/// Avanza el reloj simulado sin pumpAndSettle (los indicadores de progreso
/// animan indefinidamente y nunca se estabilizan). Las cargas están
/// encadenadas —participaciones, luego el partido de cada una— y necesitan
/// varios avances.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<void> _pump(WidgetTester tester, {required String userId}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          _SignedInAuthRepository(userId),
        ),
      ],
      child: const MaterialApp(
        home: Scaffold(body: MyParticipationsPage()),
      ),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('en un partido propio se muestra el distintivo de organizador', (
    tester,
  ) async {
    // fake-user-1 organiza m4 (Vóleibol en Maipú).
    await _pump(tester, userId: 'fake-user-1');

    expect(find.text('Vóleibol en Maipú'), findsOneWidget);
    // El organizador ve "Eres el organizador", no el estado de participación.
    expect(find.text('Eres el organizador'), findsOneWidget);
    expect(
      find.textContaining('Solicitud de participación'),
      findsNothing,
    );
    // Gestiona solicitudes desde aquí.
    expect(find.text('Gestionar solicitudes'), findsOneWidget);
  });

  testWidgets('el organizador no ve el acceso rápido de asistencia', (
    tester,
  ) async {
    await _pump(tester, userId: 'fake-user-1');

    // La asistencia se gestiona desde el detalle, no como acceso rápido aquí.
    expect(find.text('Confirmar'), findsNothing);
    expect(find.text('No asistiré'), findsNothing);
  });
}
