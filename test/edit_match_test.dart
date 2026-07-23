import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/matches/data/matches_providers.dart';
import 'package:bvg_matchmaking/features/matches/presentation/edit_match_page.dart';
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
  for (var i = 0; i < 4; i++) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

Future<ProviderContainer> _pumpEdit(
  WidgetTester tester, {
  required String userId,
  String matchId = 'm4',
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
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
      child: MaterialApp(home: EditMatchPage(matchId: matchId)),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('el formulario llega con los datos del partido', (tester) async {
    // m4 lo organiza fake-user-1.
    await _pumpEdit(tester, userId: 'fake-user-1');

    expect(find.text('Vóleibol en Maipú'), findsOneWidget);
    expect(find.text('Maipú'), findsOneWidget);
    expect(find.text('Gimnasio Municipal'), findsOneWidget);
    // El deporte no se cambia una vez publicado.
    expect(find.text('Vóleibol'), findsOneWidget);
  });

  testWidgets('guardar actualiza el partido', (tester) async {
    final container = await _pumpEdit(tester, userId: 'fake-user-1');

    // Orden de los TextField: título, descripción, comuna, lugar.
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Vóleibol en Maipú (nuevo horario)');
    await tester.enterText(fields.at(3), 'Gimnasio Parque Tres Poniente');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar cambios'));
    await _settle(tester);

    final match = await tester.runAsync(
      () => container.read(matchRepositoryProvider).getMatch('m4'),
    );
    expect(match!.title, 'Vóleibol en Maipú (nuevo horario)');
    expect(match.locationText, 'Gimnasio Parque Tres Poniente');
  });

  testWidgets('el máximo de cupos no baja de los ya aceptados',
      (tester) async {
    // m4 tiene 2 aceptados, así que el mínimo del contador es 2.
    await _pumpEdit(tester, userId: 'fake-user-1');

    final minus = find.byIcon(Icons.remove);
    // El primer contador es el de máximo de jugadores (parte en 12).
    for (var i = 0; i < 15; i++) {
      final button = tester.widget<IconButton>(
        find.ancestor(of: minus.first, matching: find.byType(IconButton)),
      );
      if (button.onPressed == null) break;
      await tester.tap(minus.first);
      await tester.pump();
    }

    expect(find.text('2'), findsWidgets);
    final button = tester.widget<IconButton>(
      find.ancestor(of: minus.first, matching: find.byType(IconButton)),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('quien no es organizador no puede editar', (tester) async {
    await _pumpEdit(tester, userId: 'user-a');

    expect(
      find.text('Solo el organizador puede editar este partido'),
      findsOneWidget,
    );
    expect(find.text('Guardar cambios'), findsNothing);
  });
}
