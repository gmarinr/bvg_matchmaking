import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match_participation.dart';
import 'manage_requests_page.dart';
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
        if (items.isEmpty) {
          return const Center(
            child: Text('Todavía no tienes participaciones.'),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              ParticipationCard(participation: items[index], userId: user.id),
        );
      },
    );
  }
}

class ParticipationCard extends ConsumerStatefulWidget {
  const ParticipationCard({
    required this.participation,
    required this.userId,
    super.key,
  });

  final MatchParticipation participation;
  final String userId;

  @override
  ConsumerState<ParticipationCard> createState() => _ParticipationCardState();
}

class _ParticipationCardState extends ConsumerState<ParticipationCard> {
  bool _loading = false;

  Future<void> _setAttendance(AttendanceStatus status) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(participationRepositoryProvider)
          .setAttendance(
            participationId: widget.participation.id,
            status: status,
          );
      ref.invalidate(myParticipationsProvider(widget.userId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_errorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final participation = widget.participation;
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
              participationStatus: participation.participationStatus,
              onTap: () => context.push(AppRoutes.matchDetailPath(match.id)),
            ),
            if (participation.isAccepted && !isOrganizer) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading
                          ? null
                          : () => _setAttendance(AttendanceStatus.declined),
                      child: const Text('No asistiré'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading
                          ? null
                          : () => _setAttendance(AttendanceStatus.confirmed),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
            if (isOrganizer) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        ManageRequestsPage(matchId: participation.matchId),
                  ),
                ),
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Gestionar solicitudes'),
              ),
            ],
            if (participation.attendanceStatus != AttendanceStatus.unknown)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Asistencia: ${participation.attendanceStatus.label}',
                  textAlign: TextAlign.center,
                ),
              ),
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
