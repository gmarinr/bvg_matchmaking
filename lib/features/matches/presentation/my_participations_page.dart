import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/enums.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match_participation.dart';
import 'providers/matches_list_providers.dart';
import 'widgets/match_card.dart';

class MyParticipationsPage extends ConsumerWidget {
  const MyParticipationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver tus partidos.'));
    }

    final participations = ref.watch(myParticipationsProvider(user.id));
    return participations.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(_errorMessage(error))),
      data: (items) {
        // Quien salió de un partido (participación cancelada) ya no lo ve aquí.
        final visible = items
            .where(
              (p) => p.participationStatus != ParticipationStatus.cancelled,
            )
            .toList();
        if (visible.isEmpty) {
          return const Center(
            child: Text('Todavía no tienes participaciones.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: visible.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              ParticipationCard(participation: visible[index], userId: user.id),
        );
      },
    );
  }
}

class ParticipationCard extends ConsumerWidget {
  const ParticipationCard({
    required this.participation,
    required this.userId,
    super.key,
  });

  final MatchParticipation participation;
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOrganizer = participation.role == ParticipantRole.organizer;
    final matchAsync = ref.watch(matchProvider(participation.matchId));
    final sportsById = ref.watch(sportsByIdProvider);

    return matchAsync.when(
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (_, _) => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No pudimos cargar este partido.'),
        ),
      ),
      data: (match) {
        if (match == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Este partido ya no está disponible.'),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MatchCard(
              match: match,
              sportName: sportsById[match.sportId]?.name ?? 'Deporte',
              // El organizador ve el distintivo de organizador; el resto, el
              // estado de su solicitud.
              participationStatus: isOrganizer
                  ? null
                  : participation.participationStatus,
              isOrganizer: isOrganizer,
              onTap: () => context.push(AppRoutes.matchDetailPath(match.id)),
            ),
            if (isOrganizer) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.push(
                  AppRoutes.manageRequestsPath(participation.matchId),
                ),
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Gestionar solicitudes'),
              ),
            ],
          ],
        );
      },
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar la información.';
}
