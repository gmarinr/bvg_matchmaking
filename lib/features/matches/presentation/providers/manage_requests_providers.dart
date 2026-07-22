import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../profile/data/profile_providers.dart';
import '../../../profile/domain/profile.dart';
import '../../data/matches_providers.dart';
import '../../domain/match_participation.dart';

/// Participaciones y solicitudes de un partido (vista del organizador).
final matchParticipantsProvider = FutureProvider.autoDispose
    .family<List<MatchParticipation>, String>((ref, matchId) async {
  return ref
      .watch(participationRepositoryProvider)
      .getParticipantsForMatch(matchId);
});

/// Perfil de un usuario, para mostrar su nombre en las solicitudes.
final userProfileProvider =
    FutureProvider.autoDispose.family<Profile?, String>((ref, userId) async {
  return ref.watch(profileRepositoryProvider).getProfile(userId);
});
