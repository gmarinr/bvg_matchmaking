import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/errors/failures.dart';
import '../data/matches_providers.dart';
import '../domain/match_participation.dart';

class ManageMatchPage extends ConsumerWidget {
  const ManageMatchPage({required this.matchId, super.key});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participants = ref.watch(matchParticipantsProvider(matchId));
    return Scaffold(
      appBar: AppBar(title: const Text('Gestionar solicitudes')),
      body: participants.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(_errorMessage(error))),
        data: (items) {
          final requests = items
              .where((item) => item.role == ParticipantRole.participant)
              .toList();
          if (requests.isEmpty) {
            return const Center(child: Text('No hay solicitudes todavía.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                RequestCard(participation: requests[index], matchId: matchId),
          );
        },
      ),
    );
  }
}

class RequestCard extends ConsumerStatefulWidget {
  const RequestCard({
    required this.participation,
    required this.matchId,
    super.key,
  });

  final MatchParticipation participation;
  final String matchId;

  @override
  ConsumerState<RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends ConsumerState<RequestCard> {
  bool _loading = false;

  Future<void> _respond(bool accept) async {
    setState(() => _loading = true);
    try {
      await ref
          .read(participationRepositoryProvider)
          .respondToRequest(
            participationId: widget.participation.id,
            accept: accept,
          );
      ref.invalidate(matchParticipantsProvider(widget.matchId));
      ref.invalidate(matchesProvider);
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
    final isPending =
        widget.participation.participationStatus == ParticipationStatus.pending;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Jugador ${widget.participation.userId}'),
            const SizedBox(height: 6),
            Text('Estado: ${widget.participation.participationStatus.wire}'),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _loading ? null : () => _respond(false),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: _loading ? null : () => _respond(true),
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _errorMessage(Object error) {
  if (error is Failure) return error.message;
  return 'No pudimos completar la operación.';
}
