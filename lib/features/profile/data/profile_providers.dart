import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/domain/sport.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'fake_profile_repository.dart';
import 'supabase_profile_repository.dart';

/// Punto único de inyección del repositorio de perfil.
///
/// PARA INTEGRAR CON SUPABASE: reemplazar `FakeProfileRepository()` por la
/// implementación real que use `supabaseClientProvider`.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseProfileRepository(ref.watch(supabaseClientProvider));
  }
  return FakeProfileRepository();
});

final profileProvider = FutureProvider.autoDispose.family<Profile?, String>(
  (ref, userId) => ref.watch(profileRepositoryProvider).getProfile(userId),
);

final sportsProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(profileRepositoryProvider).getSports(),
);

final userSportsProvider = FutureProvider.autoDispose
    .family<List<UserSport>, String>(
      (ref, userId) =>
          ref.watch(profileRepositoryProvider).getUserSports(userId),
    );
