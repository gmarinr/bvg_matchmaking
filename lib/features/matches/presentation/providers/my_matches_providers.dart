import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/data/auth_providers.dart';
import '../../data/matches_providers.dart';
import '../../domain/match.dart';
import '../../domain/match_participation.dart';

/// Un partido en el que participo, junto con mi fila de participación.
class MyParticipationEntry {
  const MyParticipationEntry({required this.match, required this.participation});

  final Match match;
  final MatchParticipation participation;
}

/// Lo que el usuario ve en "Mis participaciones": lo que organiza y aquello
/// a lo que se sumó (o pidió sumarse).
class MyMatches {
  const MyMatches({required this.organized, required this.joined});

  static const empty = MyMatches(organized: [], joined: []);

  final List<Match> organized;
  final List<MyParticipationEntry> joined;

  bool get isEmpty => organized.isEmpty && joined.isEmpty;
}

/// Partidos del usuario actual, separados por rol. Las participaciones con rol
/// `organizer` no se repiten en "participo": ya están en "organizo".
final myMatchesProvider = FutureProvider.autoDispose<MyMatches>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return MyMatches.empty;

  final matchRepo = ref.watch(matchRepositoryProvider);
  final participationRepo = ref.watch(participationRepositoryProvider);

  final organized = await matchRepo.getMyOrganizedMatches(user.id);
  final rows = await participationRepo.getMyParticipations(user.id);

  final joined = <MyParticipationEntry>[];
  for (final row in rows) {
    if (row.isOrganizer) continue;
    final match = await matchRepo.getMatch(row.matchId);
    if (match == null) continue;
    joined.add(MyParticipationEntry(match: match, participation: row));
  }

  organized.sort((a, b) => a.startAt.compareTo(b.startAt));
  joined.sort((a, b) => a.match.startAt.compareTo(b.match.startAt));

  return MyMatches(organized: organized, joined: joined);
});
