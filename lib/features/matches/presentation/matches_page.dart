import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/failures.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';

class MatchesPage extends ConsumerWidget {
  const MatchesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider);
    if (user == null) {
      return const Center(child: Text('Inicia sesión para ver partidos.'));
    }

    final matches = ref.watch(matchesProvider);
    return matches.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _ErrorState(
        message: _errorMessage(error),
        onRetry: () => ref.invalidate(matchesProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 180),
                Center(child: Text('No hay partidos disponibles.')),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(matchesProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                MatchCard(match: items[index], currentUserId: user.id),
          ),
        );
      },
    );
  }
}

class MatchCard extends ConsumerStatefulWidget {
  const MatchCard({
    required this.match,
    required this.currentUserId,
    super.key,
  });

  final Match match;
  final String currentUserId;

  @override
  ConsumerState<MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends ConsumerState<MatchCard> {
  bool _loading = false;

  Future<void> _requestToJoin() async {
    setState(() => _loading = true);
    try {
      await ref
          .read(participationRepositoryProvider)
          .requestToJoin(
            matchId: widget.match.id,
            userId: widget.currentUserId,
          );
      ref.invalidate(matchesProvider);
      ref.invalidate(myParticipationsProvider(widget.currentUserId));
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Solicitud enviada.')));
      }
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
    final match = widget.match;
    final isOrganizer = match.organizerId == widget.currentUserId;
    final canJoin = match.isJoinable && !isOrganizer;
    final date = DateFormat('dd/MM HH:mm').format(match.startAt.toLocal());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    match.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text(
                    '${match.acceptedCount}/${match.maxParticipants}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('$date  ·  ${match.commune}'),
            Text(match.locationText),
            if (match.description?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(match.description!),
            ],
            const SizedBox(height: 12),
            if (isOrganizer)
              const Text('Organizas este partido.')
            else
              FilledButton.icon(
                onPressed: canJoin && !_loading ? _requestToJoin : null,
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_outlined),
                label: Text(canJoin ? 'Solicitar participación' : 'Sin cupos'),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Reintentar')),
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
