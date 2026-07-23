import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/enums.dart';
import '../../../core/utils/labels.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';
import 'providers/matches_list_providers.dart';
import 'providers/my_matches_providers.dart';
import 'widgets/match_card.dart';

/// "Mis participaciones": los partidos que organizo y aquellos a los que me
/// sumé o pedí sumarme, con el estado de cada solicitud.
class MyMatchesPage extends ConsumerWidget {
  const MyMatchesPage({super.key, this.onOpenMatch});

  final void Function(Match match)? onOpenMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myMatchesProvider);

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Organizo'),
              Tab(text: 'Participo'),
            ],
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, _) => _Message(
                icon: Icons.cloud_off_outlined,
                title: 'No pudimos cargar tus partidos',
                action: FilledButton.icon(
                  onPressed: () => ref.invalidate(myMatchesProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ),
              data: (data) => TabBarView(
                children: [
                  _OrganizedTab(matches: data.organized, onOpen: onOpenMatch),
                  _JoinedTab(entries: data.joined, onOpen: onOpenMatch),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizedTab extends ConsumerWidget {
  const _OrganizedTab({required this.matches, required this.onOpen});

  final List<Match> matches;
  final void Function(Match match)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (matches.isEmpty) {
      return const _Message(
        icon: Icons.sports_outlined,
        title: 'Aún no organizas ningún partido',
        subtitle: 'Publica uno y aparecerá aquí para que gestiones solicitudes.',
      );
    }

    final sports = ref.watch(sportsByIdProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myMatchesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: matches.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final match = matches[i];
          return MatchCard(
            match: match,
            sportName: sports[match.sportId]?.name ?? 'Deporte',
            onTap: onOpen == null ? null : () => onOpen!(match),
            footer: _OrganizerFooter(match: match),
          );
        },
      ),
    );
  }
}

class _JoinedTab extends ConsumerWidget {
  const _JoinedTab({required this.entries, required this.onOpen});

  final List<MyParticipationEntry> entries;
  final void Function(Match match)? onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (entries.isEmpty) {
      return const _Message(
        icon: Icons.how_to_reg_outlined,
        title: 'Todavía no participas en ningún partido',
        subtitle: 'Busca uno que te acomode y envía tu solicitud.',
      );
    }

    final sports = ref.watch(sportsByIdProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(myMatchesProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final entry = entries[i];
          return MatchCard(
            match: entry.match,
            sportName: sports[entry.match.sportId]?.name ?? 'Deporte',
            onTap: onOpen == null ? null : () => onOpen!(entry.match),
            footer: _ParticipationFooter(participation: entry.participation),
          );
        },
      ),
    );
  }
}

/// Pie de la tarjeta cuando organizo: recuerda cuánto falta para confirmar.
class _OrganizerFooter extends StatelessWidget {
  const _OrganizerFooter({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final faltan = match.minParticipants - match.acceptedCount;

    final (icon, text) = switch (match.status) {
      MatchStatus.cancelled => (Icons.block, 'Cancelaste este partido.'),
      MatchStatus.completed => (Icons.flag_outlined, 'Partido finalizado.'),
      MatchStatus.confirmed => (
          Icons.verified_outlined,
          'Confirmado. Ya puedes marcarlo como finalizado.',
        ),
      _ when faltan > 0 => (
          Icons.group_add_outlined,
          'Faltan $faltan para alcanzar el mínimo.',
        ),
      _ => (
          Icons.check_circle_outline,
          'Tienes el mínimo: puedes confirmar el partido.',
        ),
    };

    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

/// Pie de la tarjeta cuando participo: estado de mi solicitud y asistencia.
class _ParticipationFooter extends StatelessWidget {
  const _ParticipationFooter({required this.participation});

  final MatchParticipation participation;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (bg, fg) = switch (participation.participationStatus) {
      ParticipationStatus.accepted => (scheme.primary, scheme.onPrimary),
      ParticipationStatus.pending => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer,
        ),
      _ => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            participation.participationStatus.label,
            style: TextStyle(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            participation.isAccepted
                ? 'Asistencia: ${participation.attendanceStatus.label.toLowerCase()}'
                : _hint(participation.participationStatus),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ),
      ],
    );
  }

  String _hint(ParticipationStatus status) => switch (status) {
        ParticipationStatus.pending => 'Esperando al organizador',
        ParticipationStatus.rejected => 'El organizador no te aceptó',
        ParticipationStatus.cancelled => 'Cancelaste tu participación',
        ParticipationStatus.accepted => '',
      };
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
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
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
