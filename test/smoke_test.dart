import 'package:bvg_matchmaking/app/app.dart';
import 'package:bvg_matchmaking/core/config/env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    if (Env.isSupabaseConfigured) {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        publishableKey: Env.supabaseAnonKey,
        authOptions: FlutterAuthClientOptions(
          localStorage: const EmptyLocalStorage(),
          pkceAsyncStorage: _MemoryGotrueAsyncStorage(),
        ),
      );
    }
  });

  testWidgets('arranca en la pantalla de inicio de sesión', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MatchMakingApp()));
    await tester.pumpAndSettle();

    // Sin sesión, el guard del router redirige a login.
    expect(find.text('Match Making'), findsOneWidget);
    expect(find.text('Iniciar sesión'), findsOneWidget);
  });
}

class _MemoryGotrueAsyncStorage implements GotrueAsyncStorage {
  final Map<String, String> _values = {};

  @override
  Future<String?> getItem({required String key}) async => _values[key];

  @override
  Future<void> removeItem({required String key}) async => _values.remove(key);

  @override
  Future<void> setItem({required String key, required String value}) async {
    _values[key] = value;
  }
}
