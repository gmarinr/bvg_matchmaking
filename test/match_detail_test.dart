import 'package:bvg_matchmaking/core/domain/enums.dart';
import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/data/matches_providers.dart';
import 'package:bvg_matchmaking/features/matches/presentation/match_detail_page.dart';
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
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 3; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<ProviderContainer> _pumpDetail(
  WidgetTester tester, {
  required String userId,
  String matchId = 'm1',
  ProviderContainer? container,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final scope = container ??
      ProviderContainer(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_SignedInAuthRepository(userId)),
        ],
      );
  if (container == null) addTearDown(scope.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: scope,
      child: MaterialApp(home: MatchDetailPage(matchId: matchId)),
    ),
  );
  await _settle(tester);
  return scope;
}

void main() {
  testWidgets('muestra los mismos campos que el formulario de creación',
      (tester) async {
    await _pumpDetail(tester, userId: 'fake-user-1');

    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
    expect(find.text('La Reina'), findsOneWidget); // comuna
    expect(find.text('Cancha Parque Padre Hurtado'), findsOneWidget); // lugar
    expect(find.text('Intermedio'), findsOneWidget); // nivel
    expect(find.text('9 de 14 jugadores'), findsOneWidget); // cupos
  });

  testWidgets('un usuario ajeno puede solicitar participación',
      (tester) async {
    await _pumpDetail(tester, userId: 'fake-user-1');

    expect(find.text('Solicitar participación'), findsOneWidget);

    await tester.tap(find.text('Solicitar participación'));
    await _settle(tester);

    expect(
      find.text('Solicitud enviada. Espera la respuesta del organizador.'),
      findsOneWidget,
    );
    expect(find.text('Cancelar solicitud'), findsOneWidget);
    // Ya no puede volver a solicitar (una sola participación por partido).
    expect(find.text('Solicitar participación'), findsNothing);
  });

  testWidgets('el organizador no ve la acción de solicitar', (tester) async {
    // Los partidos semilla m1–m3 tienen organizerId = 'other-user'.
    await _pumpDetail(tester, userId: 'other-user');

    expect(find.text('Gestionar solicitudes'), findsOneWidget);
    expect(find.text('Solicitar participación'), findsNothing);
  });

  testWidgets('sin el mínimo de participantes no se puede confirmar',
      (tester) async {
    // m1 tiene 9 aceptados y exige 10.
    await _pumpDetail(tester, userId: 'other-user');

    expect(
      find.text('Necesitas 1 participante(s) más para poder confirmar.'),
      findsOneWidget,
    );
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirmar partido'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('con el mínimo alcanzado el organizador confirma el partido',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider
            .overrideWithValue(_SignedInAuthRepository('fake-user-1')),
      ],
    );
    addTearDown(container.dispose);

    // m4 (organizado por fake-user-1) exige 4 y parte con 2 aceptados:
    // aceptar las dos solicitudes pendientes alcanza el mínimo.
    await tester.runAsync(() async {
      final repo = container.read(participationRepositoryProvider);
      await repo.respondToRequest(participationId: 'p3', accept: true);
      await repo.respondToRequest(participationId: 'p4', accept: true);
    });

    await _pumpDetail(
      tester,
      userId: 'fake-user-1',
      matchId: 'm4',
      container: container,
    );

    expect(
      find.text('Ya tienes el mínimo de participantes: puedes confirmar.'),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Confirmar partido'));
    await _settle(tester);

    final match = await tester.runAsync(
      () => container.read(matchRepositoryProvider).getMatch('m4'),
    );
    expect(match!.status, MatchStatus.confirmed);
    // Confirmado, la siguiente acción disponible es finalizarlo.
    expect(find.text('Marcar como finalizado'), findsOneWidget);
  });
}
