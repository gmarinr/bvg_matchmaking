import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/profile_repository.dart';
import 'fake_profile_repository.dart';

/// Punto único de inyección del repositorio de perfil.
///
/// PARA INTEGRAR CON SUPABASE: reemplazar `FakeProfileRepository()` por la
/// implementación real que use `supabaseClientProvider`.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return FakeProfileRepository();
});
