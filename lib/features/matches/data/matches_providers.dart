import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/match_repository.dart';
import '../domain/participation_repository.dart';
import 'fake_match_repository.dart';
import 'fake_participation_repository.dart';
import 'supabase_match_repository.dart';
import 'supabase_participation_repository.dart';

/// Punto único de inyección del repositorio de partidos.
///
/// PARA INTEGRAR CON SUPABASE: reemplazar el fake por la implementación real.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseMatchRepository(ref.watch(supabaseClientProvider));
  }
  return FakeMatchRepository();
});

/// Punto único de inyección del repositorio de participaciones.
final participationRepositoryProvider = Provider<ParticipationRepository>((
  ref,
) {
  if (Env.isSupabaseConfigured) {
    return SupabaseParticipationRepository(ref.watch(supabaseClientProvider));
  }
  return FakeParticipationRepository();
});
