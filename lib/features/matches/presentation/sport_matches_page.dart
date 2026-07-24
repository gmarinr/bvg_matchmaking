import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/domain/sport.dart';
import 'matches_list_page.dart';
import 'providers/matches_list_providers.dart';
import 'widgets/sport_selector_card.dart';

/// Resultados de partidos para un deporte seleccionado desde su tarjeta.
class SportMatchesPage extends ConsumerStatefulWidget {
  const SportMatchesPage({super.key, required this.sportId});

  final String sportId;

  @override
  ConsumerState<SportMatchesPage> createState() => _SportMatchesPageState();
}

class _SportMatchesPageState extends ConsumerState<SportMatchesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(matchFilterProvider.notifier).setSport(widget.sportId);
      }
    });
  }

  @override
  void dispose() {
    ref.read(matchFilterProvider.notifier).clearAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sportsAsync = ref.watch(sportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Partidos por deporte')),
      body: sportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const _SportMessage(
          icon: Icons.cloud_off_outlined,
          title: 'No pudimos cargar los deportes',
        ),
        data: (sports) {
          Sport? sport;
          for (final candidate in sports) {
            if (candidate.id == widget.sportId) {
              sport = candidate;
              break;
            }
          }
          if (sport == null) {
            return const _SportMessage(
              icon: Icons.search_off,
              title: 'Este deporte ya no está disponible',
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: SportHeroHeader(sport: sport),
              ),
              Expanded(
                child: MatchesListPage(
                  showSportSelector: false,
                  onOpenMatch: (match) => context.push(
                    AppRoutes.matchDetailPath(match.id),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SportMessage extends StatelessWidget {
  const _SportMessage({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
