import 'package:bvg_matchmaking/features/auth/data/auth_providers.dart';
import 'package:bvg_matchmaking/features/auth/domain/auth_repository.dart';
import 'package:bvg_matchmaking/features/profile/data/profile_providers.dart';
import 'package:bvg_matchmaking/features/profile/presentation/profile_page.dart';
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

Future<ProviderContainer> _pumpProfile(
  WidgetTester tester, {
  String userId = 'fake-user-1',
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
      child: const MaterialApp(home: Scaffold(body: ProfilePage())),
    ),
  );
  await _settle(tester);
  return container;
}

void main() {
  testWidgets('carga el perfil existente en el formulario', (tester) async {
    await _pumpProfile(tester);

    // 'Tu perfil' es el nombre semilla de fake-user-1: aparece en la cabecera
    // y en el campo de texto.
    expect(find.text('Tu perfil'), findsNWidgets(2));
    expect(find.text('Santiago'), findsOneWidget);
    expect(find.text('Todavía no declaras ningún deporte.'), findsOneWidget);
  });

  testWidgets('guardar actualiza el nombre y la comuna', (tester) async {
    final container = await _pumpProfile(tester);

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Rodrigo Álvarez');
    await tester.enterText(fields.at(1), 'Providencia');
    await tester.pump();

    await tester.tap(find.widgetWithText(FilledButton, 'Guardar perfil'));
    await _settle(tester);

    final saved = await tester.runAsync(
      () => container.read(profileRepositoryProvider).getProfile('fake-user-1'),
    );
    expect(saved!.displayName, 'Rodrigo Álvarez');
    expect(saved.commune, 'Providencia');
  });

  testWidgets('agregar un deporte lo deja con nivel autodeclarado',
      (tester) async {
    final container = await _pumpProfile(tester);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Agregar deporte'));
    await _settle(tester);

    await tester.tap(find.widgetWithText(ListTile, 'Fútbol'));
    await _settle(tester);

    final mine = await tester.runAsync(
      () =>
          container.read(profileRepositoryProvider).getUserSports('fake-user-1'),
    );
    expect(mine, hasLength(1));
    expect(mine!.first.sportId, 'futbol');

    // Cambiar el nivel desde la tarjeta del deporte.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Avanzado'));
    await _settle(tester);

    final updated = await tester.runAsync(
      () =>
          container.read(profileRepositoryProvider).getUserSports('fake-user-1'),
    );
    expect(updated!.first.skillLevel.wire, 'advanced');
  });
}
