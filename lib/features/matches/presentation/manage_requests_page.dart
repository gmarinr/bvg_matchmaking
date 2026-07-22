import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';
import 'providers/manage_requests_providers.dart';
import 'providers/match_detail_providers.dart';
import 'providers/matches_list_providers.dart';

/// Gestión de solicitudes de un partido. Solo el organizador puede aceptar o
/// rechazar; el resto ve un aviso de acceso no autorizado.
class ManageRequestsPage extends ConsumerWidget {
  const ManageRequestsPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final user = ref.watch(authRepositoryProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Solicitudes')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _Message(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar el partido',
          action: FilledButton.icon(
            onPressed: () => ref.invalidate(matchDetailProvider(matchId)),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
        data: (match) {
          if (match == null) {
            return const _Message(
              icon: Icons.search_off,
              title: 'Este partido ya no está disponible',
            );
          }
          if (user == null || match.organizerId != user.id) {
            return const _Message(
              icon: Icons.lock_outline,
              title: 'Solo el organizador puede gestionar las solicitudes',
            );
          }
          return _RequestsBody(match: match);
        },
      ),
    );
  }
}

class _RequestsBody extends ConsumerWidget {
  const _RequestsBody({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final participantsAsync = ref.watch(matchParticipantsProvider(match.id));

    return participantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => _Message(
        icon: Icons.cloud_off_outlined,
        title: 'No pudimos cargar las solicitudes',
        action: FilledButton.icon(
          onPressed: () =>
              ref.invalidate(matchParticipantsProvider(match.id)),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
        ),
      ),
      data: (rows) {
        final pending = rows
            .where((p) =>
                p.participationStatus == ParticipationStatus.pending)
            .toList();
        final accepted = rows
            .where((p) =>
                p.participationStatus == ParticipationStatus.accepted)
            .toList();
        final closed = rows
            .where((p) =>
                p.participationStatus == ParticipationStatus.rejected ||
                p.participationStatus == ParticipationStatus.cancelled)
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            _CapacityHeader(match: match),
            const SizedBox(height: 24),
            _SectionTitle(
              'Pendientes',
              count: pending.length,
            ),
            const SizedBox(height: 8),
            if (pending.isEmpty)
              _EmptyHint(
                text: 'No tienes solicitudes por responder.',
              )
            else
              for (final p in pending) ...[
                _RequestTile(match: match, participation: p, pending: true),
                const SizedBox(height: 10),
              ],
            const SizedBox(height: 20),
            _SectionTitle('Participantes', count: accepted.length),
            const SizedBox(height: 8),
            if (accepted.isEmpty)
              _EmptyHint(text: 'Aún no hay participantes aceptados.')
            else
              for (final p in accepted) ...[
                _RequestTile(match: match, participation: p, pending: false),
                const SizedBox(height: 10),
              ],
            if (closed.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionTitle('Cerradas', count: closed.length),
              const SizedBox(height: 8),
              for (final p in closed) ...[
                _RequestTile(match: match, participation: p, pending: false),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 12),
            Text(
              'Rechazar una solicitud no ocupa un cupo.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CapacityHeader extends StatelessWidget {
  const _CapacityHeader({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = match.maxParticipants == 0
        ? 0.0
        : match.acceptedCount / match.maxParticipants;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            match.title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${match.acceptedCount} de ${match.maxParticipants} cupos ocupados · estado: ${match.status.label}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _RequestTile extends ConsumerStatefulWidget {
  const _RequestTile({
    required this.match,
    required this.participation,
    required this.pending,
  });

  final Match match;
  final MatchParticipation participation;
  final bool pending;

  @override
  ConsumerState<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends ConsumerState<_RequestTile> {
  bool _busy = false;

  Future<void> _respond(bool accept) async {
    setState(() => _busy = true);
    try {
      await ref.read(participationRepositoryProvider).respondToRequest(
            participationId: widget.participation.id,
            accept: accept,
          );
      ref.invalidate(matchParticipantsProvider(widget.match.id));
      ref.invalidate(matchDetailProvider(widget.match.id));
      ref.invalidate(matchesListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept
                ? 'Solicitud aceptada.'
                : 'Solicitud rechazada.'),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pudimos responder la solicitud.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final p = widget.participation;
    final profileAsync = ref.watch(userProfileProvider(p.userId));
    final name = profileAsync.valueOrNull?.displayName ?? p.userId;
    final commune = profileAsync.valueOrNull?.commune;

    // Sin cupos libres no se puede aceptar otra solicitud.
    final canAccept = widget.match.freeSlots > 0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: scheme.primaryContainer,
                foregroundColor: scheme.onPrimaryContainer,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      [
                        if (p.isOrganizer) 'Organizador',
                        ?commune,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!widget.pending)
                _StateChip(
                  label: p.isAccepted
                      ? p.attendanceStatus.label
                      : p.participationStatus.label,
                ),
            ],
          ),
          if (widget.pending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => _respond(false),
                    child: const Text('Rechazar'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _busy || !canAccept
                        ? null
                        : () => _respond(true),
                    child: Text(canAccept ? 'Aceptar' : 'Sin cupos'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: scheme.onSurfaceVariant,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.count});

  final String text;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          text,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 8),
        Text(
          '($count)',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: TextStyle(color: scheme.onSurfaceVariant),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.title, this.action});

  final IconData icon;
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
