import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/enums.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';
import 'providers/match_detail_providers.dart';
import 'providers/matches_list_providers.dart';
import 'widgets/sport_pill.dart';

/// Detalle de un partido. Muestra los mismos campos que el formulario de
/// creación y ofrece la acción que corresponde según quién lo mira.
class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle del partido')),
      body: matchAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => _CenteredMessage(
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
            return const _CenteredMessage(
              icon: Icons.search_off,
              title: 'Este partido ya no está disponible',
            );
          }
          return _MatchDetailBody(match: match);
        },
      ),
      bottomNavigationBar: matchAsync.maybeWhen(
        data: (match) => match == null ? null : _ActionBar(match: match),
        orElse: () => null,
      ),
    );
  }
}

class _MatchDetailBody extends ConsumerWidget {
  const _MatchDetailBody({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sportName =
        ref.watch(sportsByIdProvider)[match.sportId]?.name ?? 'Deporte';

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(
          children: [
            Flexible(
              child: SportPill(
                matchId: match.id,
                sportId: match.sportId,
                sportName: sportName,
              ),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: match.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          match.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        if (match.description != null && match.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            match.description!,
            style: TextStyle(color: scheme.onSurfaceVariant, height: 1.5),
          ),
        ],
        const SizedBox(height: 24),
        _SlotsCard(match: match),
        const SizedBox(height: 20),
        _InfoRow(
          icon: Icons.event_outlined,
          label: 'Fecha y hora',
          value: AppDate.medium(match.startAt),
        ),
        _InfoRow(
          icon: Icons.map_outlined,
          label: 'Comuna',
          value: match.commune,
        ),
        _InfoRow(
          icon: Icons.place_outlined,
          label: 'Lugar',
          value: match.locationText,
        ),
        _InfoRow(
          icon: Icons.trending_up,
          label: 'Nivel',
          value: match.skillLevel.label,
        ),
      ],
    );
  }
}

class _SlotsCard extends StatelessWidget {
  const _SlotsCard({required this.match});

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
          Row(
            children: [
              Icon(Icons.group_outlined, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                '${match.acceptedCount} de ${match.maxParticipants} jugadores',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
            match.freeSlots > 0
                ? '${match.freeSlots} cupo${match.freeSlots == 1 ? '' : 's'} disponible${match.freeSlots == 1 ? '' : 's'} · mínimo ${match.minParticipants} para confirmar'
                : 'Sin cupos disponibles · mínimo ${match.minParticipants} para confirmar',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: scheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      MatchStatus.open => (scheme.tertiary, scheme.onTertiary),
      MatchStatus.full => (scheme.errorContainer, scheme.onErrorContainer),
      MatchStatus.confirmed => (scheme.primary, scheme.onPrimary),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    this.action,
  });

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
            Text(
              title,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Barra inferior con la acción disponible según rol y estado.
class _ActionBar extends ConsumerStatefulWidget {
  const _ActionBar({required this.match});

  final Match match;

  @override
  ConsumerState<_ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends ConsumerState<_ActionBar> {
  bool _busy = false;

  Match get _match => widget.match;

  void _refresh() {
    ref.invalidate(myParticipationProvider(_match.id));
    ref.invalidate(matchDetailProvider(_match.id));
    ref.invalidate(matchesListProvider);
    // También la lista de "Mis partidos", para que el estado de asistencia se
    // actualice fuera del detalle.
    final userId = ref.read(authRepositoryProvider).currentUser?.id;
    if (userId != null) ref.invalidate(myParticipationsProvider(userId));
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      _toast(okMessage);
    } catch (e) {
      // Mostramos el motivo real (p. ej. permiso RLS) en vez de un genérico,
      // para poder diagnosticar fallos del backend.
      _toast(e is Failure ? e.message : 'No pudimos completar la acción.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _request(String userId) => _run(
    () => ref
        .read(participationRepositoryProvider)
        .requestToJoin(matchId: _match.id, userId: userId),
    'Solicitud enviada al organizador.',
  );

  Future<void> _cancel(String participationId) => _run(
    () => ref
        .read(participationRepositoryProvider)
        .cancelParticipation(participationId),
    'Cancelaste tu solicitud.',
  );

  /// Salir del partido. Avisa que el cupo se libera y que para volver hay que
  /// solicitar un cupo de nuevo.
  Future<void> _confirmLeave(MatchParticipation participation) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿No podrás ir?'),
        content: const Text(
          'Saldrás del partido y tu cupo quedará libre para otra persona. '
          'Si más adelante quieres participar, deberás solicitar un cupo de '
          'nuevo y esperar que el organizador te acepte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, no podré ir'),
          ),
        ],
      ),
    );
    if (leave != true) return;
    await _run(
      () => ref
          .read(participationRepositoryProvider)
          .cancelParticipation(participation.id),
      'Saliste del partido. Tu cupo quedó libre.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authRepositoryProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final participationAsync = ref.watch(myParticipationProvider(_match.id));
    final isOrganizer = _match.organizerId == user.id;

    return _BarShell(
      child: participationAsync.when(
        loading: () => const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
        ),
        error: (_, _) => const Text('No pudimos cargar tu participación.'),
        data: (participation) => isOrganizer
            ? _organizerActions()
            : _participantActions(user.id, participation),
      ),
    );
  }

  Widget _organizerActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Note(
          icon: Icons.shield_outlined,
          text: 'Eres el organizador de este partido.',
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              context.push(AppRoutes.manageRequestsPath(_match.id)),
          icon: const Icon(Icons.inbox_outlined),
          label: const Text('Gestionar solicitudes'),
        ),
      ],
    );
  }

  Widget _participantActions(String userId, MatchParticipation? participation) {
    // Quien salió del partido (participación cancelada) vuelve a la situación de
    // poder solicitar un cupo, tras el aviso de que debe pedir permiso de nuevo.
    final leftBefore =
        participation?.participationStatus == ParticipationStatus.cancelled;

    if (participation == null || leftBefore) {
      if (!_match.isJoinable) {
        return _Note(icon: Icons.block, text: _notJoinableReason());
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leftBefore) ...[
            _Note(
              icon: Icons.info_outline,
              text:
                  'Saliste de este partido. Para volver, solicita un cupo otra vez.',
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _busy ? null : () => _request(userId),
              icon: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : const Icon(Icons.how_to_reg),
              label: Text(_busy ? 'Enviando…' : 'Solicitar participación'),
            ),
          ),
        ],
      );
    }

    return switch (participation.participationStatus) {
      ParticipationStatus.pending => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Note(
            icon: Icons.hourglass_top,
            text: 'Solicitud enviada. Espera la respuesta del organizador.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _busy ? null : () => _cancel(participation.id),
            child: const Text('Cancelar solicitud'),
          ),
        ],
      ),
      ParticipationStatus.accepted => _acceptedActions(participation),
      ParticipationStatus.rejected => _Note(
        icon: Icons.cancel_outlined,
        text: 'Tu solicitud fue rechazada.',
      ),
      // Manejado arriba (leftBefore); rama requerida por exhaustividad.
      ParticipationStatus.cancelled => const SizedBox.shrink(),
    };
  }

  /// Ser aceptado ya cuenta como asistencia: no hay paso de confirmación. La
  /// única acción es avisar que no se podrá ir, que libera el cupo.
  Widget _acceptedActions(MatchParticipation participation) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Note(
          icon: Icons.check_circle_outline,
          text: 'Estás participando en este partido.',
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _busy ? null : () => _confirmLeave(participation),
            child: const Text('No podré ir'),
          ),
        ),
      ],
    );
  }

  String _notJoinableReason() => switch (_match.status) {
    MatchStatus.cancelled => 'Este partido fue cancelado.',
    MatchStatus.completed => 'Este partido ya se jugó.',
    MatchStatus.full => 'No quedan cupos disponibles.',
    MatchStatus.confirmed =>
      'El partido ya fue confirmado y no acepta solicitudes.',
    MatchStatus.draft => 'Este partido aún no se publica.',
    MatchStatus.open => 'No quedan cupos disponibles.',
  };
}

class _BarShell extends StatelessWidget {
  const _BarShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        decoration: BoxDecoration(
          color: scheme.surface,
          border: Border(top: BorderSide(color: scheme.outlineVariant)),
        ),
        child: child,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}
