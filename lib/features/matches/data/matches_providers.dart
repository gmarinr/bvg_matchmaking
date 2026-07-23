import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';
import '../domain/match_repository.dart';
import '../domain/participation_repository.dart';
import 'fake_match_repository.dart';
import 'fake_participation_repository.dart';
import 'in_memory_match_store.dart';
import 'supabase_match_repository.dart';
import 'supabase_participation_repository.dart';

/// Shared fake store. The real app uses Supabase when configured.
final _matchStoreProvider = Provider<InMemoryMatchStore>((ref) {
  return InMemoryMatchStore();
});

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseMatchRepository(ref.watch(supabaseClientProvider));
  }
  return FakeMatchRepository(ref.watch(_matchStoreProvider));
});

final participationRepositoryProvider = Provider<ParticipationRepository>((
  ref,
) {
  if (Env.isSupabaseConfigured) {
    return SupabaseParticipationRepository(ref.watch(supabaseClientProvider));
  }
  return FakeParticipationRepository(ref.watch(_matchStoreProvider));
});

final matchesProvider = FutureProvider.autoDispose<List<Match>>(
  (ref) =>
      ref.watch(matchRepositoryProvider).searchMatches(const MatchFilter()),
);

final matchProvider = FutureProvider.autoDispose.family<Match?, String>(
  (ref, matchId) => ref.watch(matchRepositoryProvider).getMatch(matchId),
);

final myParticipationsProvider = FutureProvider.autoDispose
    .family<List<MatchParticipation>, String>(
      (ref, userId) => ref
          .watch(participationRepositoryProvider)
          .getMyParticipations(userId),
    );
