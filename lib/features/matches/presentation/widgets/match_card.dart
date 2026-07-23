import 'package:flutter/material.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/utils/app_date.dart';
import '../../../../core/utils/labels.dart';
import '../../domain/match.dart';
import 'sport_pill.dart';

/// Tarjeta que resume un partido en la lista de búsqueda.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.sportName,
    this.onTap,
    this.footer,
  });

  final Match match;
  final String sportName;
  final VoidCallback? onTap;

  /// Contenido extra al pie de la tarjeta, p. ej. el estado de mi solicitud.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: SportPill(
                      matchId: match.id,
                      sportName: sportName,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: match.status),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                match.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              _IconRow(
                icon: Icons.event_outlined,
                text: AppDate.short(match.startAt),
              ),
              const SizedBox(height: 6),
              _IconRow(
                icon: Icons.place_outlined,
                text: '${match.commune} · ${match.locationText}',
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Flexible(
                    child: _Pill(
                      label: match.skillLevel.label,
                      color: scheme.secondaryContainer,
                      onColor: scheme.onSecondaryContainer,
                      icon: Icons.trending_up,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Slots(match: match),
                ],
              ),
              if (footer != null) ...[
                const SizedBox(height: 14),
                Divider(height: 1, color: scheme.outlineVariant),
                const SizedBox(height: 12),
                footer!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _Slots extends StatelessWidget {
  const _Slots({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final full = match.freeSlots == 0;
    return Row(
      children: [
        Icon(Icons.group_outlined,
            size: 18,
            color: full ? scheme.error : scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          '${match.acceptedCount}/${match.maxParticipants}',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: full ? scheme.error : scheme.onSurface,
          ),
        ),
        if (!full) ...[
          const SizedBox(width: 4),
          Text(
            '· ${match.freeSlots} libre${match.freeSlots == 1 ? '' : 's'}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.onColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color onColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: onColor),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: onColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
