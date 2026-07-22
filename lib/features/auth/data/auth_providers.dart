import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import 'fake_auth_repository.dart';

/// Punto único de inyección del repositorio de auth.
///
/// PARA INTEGRAR CON SUPABASE: reemplazar `FakeAuthRepository()` por
/// `SupabaseAuthRepository(ref.watch(supabaseClientProvider))`. Ningún widget
/// cambia: todos dependen de la interfaz `AuthRepository`.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FakeAuthRepository();
});

/// Sesión actual como stream. La UI y el router escuchan este provider para
/// redirigir según haya o no usuario autenticado.
final authStateProvider = StreamProvider<AppUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges();
});
