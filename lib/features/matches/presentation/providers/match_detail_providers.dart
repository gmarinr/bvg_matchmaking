import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_providers.dart';
import '../../data/matches_providers.dart';
import '../../domain/match.dart';
import '../../domain/match_participation.dart';

/// Partido consultado por id. `null` si no existe.
final matchDetailProvider = FutureProvider.autoDispose.family<Match?, String>((
  ref,
  matchId,
) async {
  return ref.watch(matchRepositoryProvider).getMatch(matchId);
});

/// Participación del usuario actual en ese partido, si existe.
/// Determina qué acción se le ofrece: solicitar, esperar, confirmar, etc.
final myParticipationProvider = FutureProvider.autoDispose
    .family<MatchParticipation?, String>((ref, matchId) async {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) return null;

      final rows = await ref
          .watch(participationRepositoryProvider)
          .getMyParticipations(user.id);
      for (final row in rows) {
        if (row.matchId == matchId) return row;
      }
      return null;
    });
