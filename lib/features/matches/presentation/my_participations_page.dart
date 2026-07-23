import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/failures.dart';
import '../../../core/domain/enums.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match_participation.dart';

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
    final status = participation.participationStatus.wire;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isOrganizer ? 'Partido organizado' : 'Solicitud de participación',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Estado: $status'),
            if (participation.isAccepted && !isOrganizer) ...[
              const SizedBox(height: 12),
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
            if (participation.attendanceStatus != AttendanceStatus.unknown)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Asistencia: ${participation.attendanceStatus.wire}',
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos cargar la información.';
}
