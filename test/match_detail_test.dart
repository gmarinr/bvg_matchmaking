import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
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
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUp({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {}
}

/// Avanza el reloj simulado sin usar pumpAndSettle (los indicadores de
/// progreso animan indefinidamente y nunca se estabilizan).
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

Future<void> _pumpDetail(
  WidgetTester tester, {
  required String userId,
  String matchId = 'm1',
}) async {
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
      child: MaterialApp(home: MatchDetailPage(matchId: matchId)),
    ),
  );
  await _settle(tester);
}

void main() {
  testWidgets('muestra los mismos campos que el formulario de creación', (
    tester,
  ) async {
    await _pumpDetail(tester, userId: 'fake-user-1');

    expect(find.text('Fútbol 7 en La Reina'), findsOneWidget);
    expect(find.text('La Reina'), findsOneWidget); // comuna
    expect(find.text('Cancha Parque Padre Hurtado'), findsOneWidget); // lugar
    expect(find.text('Intermedio'), findsOneWidget); // nivel
    expect(find.text('9 de 14 jugadores'), findsOneWidget); // cupos
  });

  testWidgets('un usuario ajeno puede solicitar participación', (tester) async {
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
    // Los partidos semilla tienen organizerId = 'other-user'.
    await _pumpDetail(tester, userId: 'other-user');

    expect(find.text('Eres el organizador de este partido.'), findsOneWidget);
    expect(find.text('Solicitar participación'), findsNothing);
  });

  testWidgets('ser aceptado ya cuenta como asistencia, sin paso de confirmar', (
    tester,
  ) async {
    // user-c es participante aceptado de m4.
    await _pumpDetail(tester, userId: 'user-c', matchId: 'm4');

    // No hay paso de confirmar: aceptado equivale a estar participando.
    expect(find.text('Estás participando en este partido.'), findsOneWidget);
    expect(find.text('Confirmar asistencia'), findsNothing);
    expect(find.text('No podré ir'), findsOneWidget);
  });

  testWidgets('al no poder ir se sale del partido y se puede re-solicitar', (
    tester,
  ) async {
    await _pumpDetail(tester, userId: 'user-c', matchId: 'm4');

    // "No podré ir" pide confirmación con la advertencia.
    await tester.tap(find.text('No podré ir'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.textContaining('deberás solicitar un cupo'), findsOneWidget);

    await tester.tap(find.text('Sí, no podré ir'));
    await _settle(tester);

    // Queda fuera del partido y se le ofrece volver a solicitar un cupo.
    expect(find.textContaining('Saliste de este partido'), findsOneWidget);
    expect(find.text('Solicitar participación'), findsOneWidget);
  });
}
