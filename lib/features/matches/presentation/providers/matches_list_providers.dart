import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/domain/enums.dart';
import '../../../../core/domain/sport.dart';
import '../../../profile/data/profile_providers.dart';
import '../../data/matches_providers.dart';
import '../../domain/match.dart';

/// Filtro de búsqueda activo. La UI lo modifica y la lista reacciona.
final matchFilterProvider = NotifierProvider<MatchFilterNotifier, MatchFilter>(
  MatchFilterNotifier.new,
);

class MatchFilterNotifier extends Notifier<MatchFilter> {
  @override
  MatchFilter build() => const MatchFilter();

  void setSport(String? sportId) =>
      state = state.copyWith(sportId: sportId, clearSport: sportId == null);

  void setCommune(String? commune) => state = state.copyWith(
    commune: commune,
    clearCommune: commune == null || commune.isEmpty,
  );

  void setSkill(SkillLevelFilter skill) => state = state.copyWith(
    skillLevel: skill.value,
    clearSkill: skill.value == null,
  );

  void setFromDate(DateTime? date) =>
      state = state.copyWith(fromDate: date, clearDate: date == null);

  void clearAll() => state = const MatchFilter();
}

/// Envoltorio para poder pasar "sin nivel" (null) por el `copyWith`.
class SkillLevelFilter {
  const SkillLevelFilter(this.value);
  final SkillLevel? value;
}

/// Resultado de la búsqueda según el filtro actual.
final matchesListProvider = FutureProvider.autoDispose<List<Match>>((
  ref,
) async {
  final filter = ref.watch(matchFilterProvider);
  final repo = ref.watch(matchRepositoryProvider);
  return repo.searchMatches(filter);
});

/// Catálogo de deportes (para chips y filtros).
final sportsProvider = FutureProvider<List<Sport>>((ref) async {
  return ref.watch(profileRepositoryProvider).getSports();
});

/// Índice deporte por id, para resolver nombres en las tarjetas.
final sportsByIdProvider = Provider<Map<String, Sport>>((ref) {
  final sports = ref.watch(sportsProvider).valueOrNull ?? const [];
  return {for (final s in sports) s.id: s};
});
