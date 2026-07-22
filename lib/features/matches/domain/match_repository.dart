import '../../../core/domain/enums.dart';
import 'match.dart';

/// Contrato de gestión de partidos (crear, buscar, editar, cambiar estado).
abstract interface class MatchRepository {
  /// Partidos publicados que cumplen el filtro (Flujo B). Sin filtro devuelve
  /// los partidos `open` visibles.
  Future<List<Match>> searchMatches(MatchFilter filter);

  Future<Match?> getMatch(String id);

  Future<Match> createMatch(Match match);

  Future<Match> updateMatch(Match match);

  /// Transición de estado del ciclo de vida (`open`, `full`, `confirmed`,
  /// `completed`, `cancelled`).
  Future<void> updateStatus(String matchId, MatchStatus status);

  /// Partidos donde el usuario es organizador (Flujo C).
  Future<List<Match>> getMyOrganizedMatches(String userId);
}
