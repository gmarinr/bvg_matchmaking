import '../../../core/domain/enums.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';
import 'in_memory_match_store.dart';

/// Implementación en memoria de partidos, apoyada en el store compartido.
class FakeMatchRepository implements MatchRepository {
  FakeMatchRepository(this._store);

  final InMemoryMatchStore _store;

  @override
  Future<List<Match>> searchMatches(MatchFilter filter) async {
    await _tick();
    return _store.matches.where((m) {
      if (m.status != MatchStatus.open && m.status != MatchStatus.full) {
        return false;
      }
      if (filter.sportId != null && m.sportId != filter.sportId) return false;
      if (filter.commune != null &&
          filter.commune!.isNotEmpty &&
          !m.commune.toLowerCase().contains(filter.commune!.toLowerCase())) {
        return false;
      }
      if (filter.skillLevel != null && m.skillLevel != filter.skillLevel) {
        return false;
      }
      if (filter.fromDate != null && m.startAt.isBefore(filter.fromDate!)) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Future<Match?> getMatch(String id) async {
    await _tick();
    return _store.findMatch(id);
  }

  @override
  Future<Match> createMatch(Match match) async {
    await _tick();
    final now = DateTime.now();
    final created = Match(
      id: _store.nextId('local'),
      organizerId: match.organizerId,
      sportId: match.sportId,
      title: match.title,
      description: match.description,
      startAt: match.startAt,
      commune: match.commune,
      locationText: match.locationText,
      skillLevel: match.skillLevel,
      minParticipants: match.minParticipants,
      maxParticipants: match.maxParticipants,
      status: match.status,
      recruitmentMode: match.recruitmentMode,
      createdAt: now,
      updatedAt: now,
      acceptedCount: 1, // el organizador cuenta como participante
    );
    _store.matches.add(created);
    return created;
  }

  @override
  Future<Match> updateMatch(Match match) async {
    await _tick();
    final i = _store.matches.indexWhere((m) => m.id == match.id);
    if (i == -1) throw StateError('Match no encontrado');
    final updated = match.copyWith(updatedAt: DateTime.now());
    _store.matches[i] = updated;
    return updated;
  }

  @override
  Future<void> updateStatus(String matchId, MatchStatus status) async {
    await _tick();
    final i = _store.matches.indexWhere((m) => m.id == matchId);
    if (i == -1) return;
    _store.matches[i] = _store.matches[i].copyWith(status: status);
  }

  @override
  Future<List<Match>> getMyOrganizedMatches(String userId) async {
    await _tick();
    return _store.matches.where((m) => m.organizerId == userId).toList();
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
