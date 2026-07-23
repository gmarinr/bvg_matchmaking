import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/enums.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/utils/labels.dart';
import '../../auth/data/auth_providers.dart';
import '../data/matches_providers.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';
import 'providers/match_detail_providers.dart';
import 'providers/matches_list_providers.dart';
import 'providers/my_matches_providers.dart';
import 'widgets/sport_pill.dart';

/// Detalle de un partido. Muestra los mismos campos que el formulario de
/// creación y ofrece la acción que corresponde según quién lo mira.
class MatchDetailPage extends ConsumerWidget {
  const MatchDetailPage({super.key, required this.matchId});

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchAsync = ref.watch(matchDetailProvider(matchId));
    final user = ref.watch(authRepositoryProvider).currentUser;
    final match = matchAsync.valueOrNull;
    final isOrganizer = match != null && user != null &&
        match.organizerId == user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del partido'),
        actions: [
          if (isOrganizer) _OrganizerMenu(match: match),
        ],
      ),
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
        data: (match) =>
            match == null ? null : _ActionBar(match: match),
        orElse: () => null,
      ),
    );
  }
}

/// Acciones secundarias del organizador: editar y cancelar el encuentro.
class _OrganizerMenu extends ConsumerWidget {
  const _OrganizerMenu({required this.match});

  final Match match;

  bool get _isClosed =>
      match.status == MatchStatus.completed ||
      match.status == MatchStatus.cancelled;

  Future<void> _confirmCancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cancelar el partido?'),
        content: const Text(
          'Se avisará a los participantes y el partido dejará de aparecer '
          'en la búsqueda. Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cancelar partido'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref
          .read(matchRepositoryProvider)
          .updateStatus(match.id, MatchStatus.cancelled);
      ref.invalidate(matchDetailProvider(match.id));
      ref.invalidate(matchesListProvider);
      ref.invalidate(myMatchesProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Partido cancelado.')),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pudimos cancelar el partido.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (_isClosed) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Opciones del organizador',
      onSelected: (value) {
        if (value == 'edit') {
          context.push(AppRoutes.editMatchPath(match.id));
        } else {
          _confirmCancel(context, ref);
        }
      },
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: 'edit',
          child: ListTile(
            leading: Icon(Icons.edit_outlined),
            title: Text('Editar partido'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'cancel',
          child: ListTile(
            leading: Icon(Icons.cancel_outlined),
            title: Text('Cancelar partido'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
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
              child: SportPill(matchId: match.id, sportName: sportName),
            ),
            const SizedBox(width: 8),
            _StatusChip(status: match.status),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          match.title,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
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
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
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
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600),
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
        style:
            TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700),
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
    ref.invalidate(myMatchesProvider);
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _run(Future<void> Function() action, String okMessage) async {
    setState(() => _busy = true);
    try {
      await action();
      _refresh();
      _toast(okMessage);
    } catch (e) {
      _toast('No pudimos completar la acción.');
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

  Future<void> _setAttendance(String participationId, AttendanceStatus s) =>
      _run(
        () => ref
            .read(participationRepositoryProvider)
            .setAttendance(participationId: participationId, status: s),
        s == AttendanceStatus.confirmed
            ? 'Confirmaste tu asistencia.'
            : 'Avisaste que no podrás ir.',
      );

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

  /// Cambia el estado del ciclo de vida del partido (Flujo C).
  Future<void> _setStatus(MatchStatus status, String okMessage) => _run(
        () => ref
            .read(matchRepositoryProvider)
            .updateStatus(_match.id, status),
        okMessage,
      );

  Widget _organizerActions() {
    // El partido solo se confirma cuando hay gente suficiente.
    final enoughPlayers = _match.acceptedCount >= _match.minParticipants;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Note(
          icon: Icons.shield_outlined,
          text: _organizerNote(enoughPlayers),
        ),
        const SizedBox(height: 12),
        if (_match.status != MatchStatus.completed &&
            _match.status != MatchStatus.cancelled)
          OutlinedButton.icon(
            onPressed: () =>
                context.push(AppRoutes.manageRequestsPath(_match.id)),
            icon: const Icon(Icons.inbox_outlined),
            label: const Text('Gestionar solicitudes'),
          ),
        ...switch (_match.status) {
          MatchStatus.open || MatchStatus.full => [
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy || !enoughPlayers
                    ? null
                    : () => _setStatus(
                          MatchStatus.confirmed,
                          'Partido confirmado.',
                        ),
                icon: const Icon(Icons.verified_outlined),
                label: const Text('Confirmar partido'),
              ),
            ],
          MatchStatus.confirmed => [
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () => _setStatus(
                          MatchStatus.completed,
                          'Partido marcado como finalizado.',
                        ),
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Marcar como finalizado'),
              ),
            ],
          MatchStatus.draft => [
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: _busy
                    ? null
                    : () =>
                        _setStatus(MatchStatus.open, 'Partido publicado.'),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Publicar partido'),
              ),
            ],
          MatchStatus.completed || MatchStatus.cancelled => const <Widget>[],
        },
      ],
    );
  }

  String _organizerNote(bool enoughPlayers) => switch (_match.status) {
        MatchStatus.cancelled => 'Cancelaste este partido.',
        MatchStatus.completed => 'Este partido ya está finalizado.',
        MatchStatus.confirmed =>
          'Partido confirmado. Márcalo como finalizado cuando ocurra.',
        MatchStatus.draft => 'Este partido aún no se publica.',
        _ when !enoughPlayers =>
          'Necesitas ${_match.minParticipants - _match.acceptedCount} '
              'participante(s) más para poder confirmar.',
        _ => 'Ya tienes el mínimo de participantes: puedes confirmar.',
      };

  Widget _participantActions(
    String userId,
    MatchParticipation? participation,
  ) {
    if (participation == null) {
      if (!_match.isJoinable) {
        return _Note(icon: Icons.block, text: _notJoinableReason());
      }
      return FilledButton.icon(
        onPressed: _busy ? null : () => _request(userId),
        icon: _busy
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              )
            : const Icon(Icons.how_to_reg),
        label: Text(_busy ? 'Enviando…' : 'Solicitar participación'),
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
      ParticipationStatus.accepted => _attendanceActions(participation),
      ParticipationStatus.rejected => _Note(
          icon: Icons.cancel_outlined,
          text: 'Tu solicitud fue rechazada.',
        ),
      ParticipationStatus.cancelled => _Note(
          icon: Icons.info_outline,
          text: 'Cancelaste tu participación en este partido.',
        ),
    };
  }

  Widget _attendanceActions(MatchParticipation participation) {
    final confirmed =
        participation.attendanceStatus == AttendanceStatus.confirmed;
    final declined =
        participation.attendanceStatus == AttendanceStatus.declined;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Note(
          icon: Icons.check_circle_outline,
          text: confirmed
              ? 'Estás dentro y confirmaste tu asistencia.'
              : declined
                  ? 'Estás dentro, pero avisaste que no podrás ir.'
                  : 'Fuiste aceptado. Confirma tu asistencia.',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy || declined
                    ? null
                    : () => _setAttendance(
                          participation.id,
                          AttendanceStatus.declined,
                        ),
                child: const Text('No podré ir'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton(
                onPressed: _busy || confirmed
                    ? null
                    : () => _setAttendance(
                          participation.id,
                          AttendanceStatus.confirmed,
                        ),
                child: const Text('Confirmar asistencia'),
              ),
            ),
          ],
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
          child: Text(
            text,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
