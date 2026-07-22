import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/data/matches_providers.dart';
import 'package:bvg_matchmaking/features/matches/presentation/manage_requests_page.dart';
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

/// Avanza el reloj simulado sin usar pumpAndSettle (los indicadores de
/// progreso animan indefinidamente y nunca se estabilizan).
///
/// Las cargas están encadenadas —partido, luego participantes, luego el perfil
/// de cada uno— y cada una arranca recién en el frame siguiente, así que hacen
/// falta varios avances.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<ProviderContainer> _pumpManage(
  WidgetTester tester, {
  required String userId,
  String matchId = 'm4',
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
      child: MaterialApp(home: ManageRequestsPage(matchId: matchId)),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('el organizador ve las solicitudes pendientes', (tester) async {
    // m4 lo organiza fake-user-1 y tiene 2 solicitudes pendientes.
    await _pumpManage(tester, userId: 'fake-user-1');

    expect(find.text('Diego Fuentes'), findsOneWidget);
    expect(find.text('Valentina Soto'), findsOneWidget);
    expect(find.text('Aceptar'), findsNWidgets(2));
    expect(find.text('Rechazar'), findsNWidgets(2));
    // 2 de 12 cupos ocupados al inicio.
    expect(
      find.textContaining('2 de 12 cupos ocupados'),
      findsOneWidget,
    );
  });

  testWidgets('aceptar una solicitud ocupa un cupo', (tester) async {
    final container = await _pumpManage(tester, userId: 'fake-user-1');

    await tester.tap(find.text('Aceptar').first);
    await _settle(tester);

    // El cupo ocupado subió de 2 a 3.
    final match = await tester.runAsync(
      () => container.read(matchRepositoryProvider).getMatch('m4'),
    );
    expect(match!.acceptedCount, 3);
    // Queda una sola solicitud pendiente.
    expect(find.text('Aceptar'), findsOneWidget);
  });

  testWidgets('rechazar una solicitud no ocupa cupo', (tester) async {
    final container = await _pumpManage(tester, userId: 'fake-user-1');

    await tester.tap(find.text('Rechazar').first);
    await _settle(tester);

    final match = await tester.runAsync(
      () => container.read(matchRepositoryProvider).getMatch('m4'),
    );
    expect(match!.acceptedCount, 2); // sin cambios
    expect(find.text('Aceptar'), findsOneWidget);
  });

  testWidgets('un usuario que no es el organizador no puede gestionar',
      (tester) async {
    await _pumpManage(tester, userId: 'user-a');

    expect(
      find.text('Solo el organizador puede gestionar las solicitudes'),
      findsOneWidget,
    );
    expect(find.text('Aceptar'), findsNothing);
  });
}
