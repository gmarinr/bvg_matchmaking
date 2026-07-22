import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/match_repository.dart';
import '../domain/participation_repository.dart';
import 'fake_match_repository.dart';
import 'fake_participation_repository.dart';
import 'in_memory_match_store.dart';

/// Store compartido por los repositorios falsos, para que las solicitudes
/// afecten los cupos del partido. Desaparece al conectar Supabase.
final _matchStoreProvider = Provider<InMemoryMatchStore>((ref) {
  return InMemoryMatchStore();
});

/// Punto único de inyección del repositorio de partidos.
///
/// PARA INTEGRAR CON SUPABASE: reemplazar el fake por la implementación real.
final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return FakeMatchRepository(ref.watch(_matchStoreProvider));
});

/// Punto único de inyección del repositorio de participaciones.
final participationRepositoryProvider =
    Provider<ParticipationRepository>((ref) {
  return FakeParticipationRepository(ref.watch(_matchStoreProvider));
});
