import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/match.dart';
import 'providers/matches_list_providers.dart';
import 'widgets/match_card.dart';
import 'widgets/matches_filter_sheet.dart';

/// Lista de partidos publicados con búsqueda por deporte y filtros avanzados.
/// Se usa dentro del contenedor Home (no incluye Scaffold propio).
class MatchesListPage extends ConsumerWidget {
  const MatchesListPage({super.key, this.onOpenMatch});

  final void Function(Match match)? onOpenMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(matchesListProvider);
    final filter = ref.watch(matchFilterProvider);

    return Column(
      children: [
        const _SportChipsRow(),
        _FilterBar(filter: filter),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async => ref.invalidate(matchesListProvider),
            child: matchesAsync.when(
              loading: () => const _SkeletonList(),
              error: (_, _) => _ErrorState(
                onRetry: () => ref.invalidate(matchesListProvider),
              ),
              data: (matches) {
                if (matches.isEmpty) {
                  return _EmptyState(
                    hasFilters: !filter.isEmpty,
                    onClear: () =>
                        ref.read(matchFilterProvider.notifier).clearAll(),
                  );
                }
                return _MatchesList(matches: matches, onOpenMatch: onOpenMatch);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _MatchesList extends ConsumerWidget {
  const _MatchesList({required this.matches, this.onOpenMatch});

  final List<Match> matches;
  final void Function(Match match)? onOpenMatch;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsById = ref.watch(sportsByIdProvider);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: matches.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final match = matches[i];
        return MatchCard(
          match: match,
          sportName: sportsById[match.sportId]?.name ?? 'Deporte',
          onTap: onOpenMatch == null ? null : () => onOpenMatch!(match),
        );
      },
    );
  }
}

class _SportChipsRow extends ConsumerWidget {
  const _SportChipsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(sportsProvider);
    final selected = ref.watch(matchFilterProvider).sportId;
    final notifier = ref.read(matchFilterProvider.notifier);

    return sportsAsync.maybeWhen(
      data: (sports) => SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Todos'),
                selected: selected == null,
                onSelected: (_) => notifier.setSport(null),
              ),
            ),
            for (final sport in sports)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(sport.name),
                  selected: selected == sport.id,
                  onSelected: (sel) => notifier.setSport(sel ? sport.id : null),
                ),
              ),
          ],
        ),
      ),
      orElse: () => const SizedBox(height: 48),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter});

  final MatchFilter filter;

  int get _advancedCount => [
    filter.commune != null && filter.commune!.isNotEmpty,
    filter.skillLevel != null,
    filter.fromDate != null,
  ].where((e) => e).length;

  @override
  Widget build(BuildContext context) {
    final count = _advancedCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => MatchesFilterSheet.show(context),
            icon: const Icon(Icons.tune, size: 18),
            label: Text(count == 0 ? 'Filtros' : 'Filtros ($count)'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasFilters, required this.onClear});

  final bool hasFilters;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      // ListView para que el pull-to-refresh siga funcionando en vacío.
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(
          Icons.sports_outlined,
          size: 64,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            hasFilters
                ? 'No hay partidos con esos filtros'
                : 'Aún no hay partidos disponibles',
            style: theme.textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            hasFilters
                ? 'Prueba ampliando la búsqueda.'
                : 'Crea el primero y arma tu partido.',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ),
        if (hasFilters) ...[
          const SizedBox(height: 20),
          Center(
            child: OutlinedButton(
              onPressed: onClear,
              child: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Icon(
          Icons.cloud_off_outlined,
          size: 64,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'No pudimos cargar los partidos',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 168,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
