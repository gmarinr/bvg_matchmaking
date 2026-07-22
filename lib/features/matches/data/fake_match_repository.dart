import '../../../core/domain/enums.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';

/// Implementación en memoria de partidos, con datos semilla para la UI.
class FakeMatchRepository implements MatchRepository {
  FakeMatchRepository() {
    _seed();
  }

  final List<Match> _matches = [];
  int _counter = 0;

  void _seed() {
    final now = DateTime.now();
    _matches.addAll([
      Match(
        id: 'm1',
        organizerId: 'other-user',
        sportId: 'futbol',
        title: 'Fútbol 7 en La Reina',
        description: 'Partido amistoso, faltan jugadores para completar.',
        startAt: now.add(const Duration(days: 2, hours: 3)),
        commune: 'La Reina',
        locationText: 'Cancha Parque Padre Hurtado',
        skillLevel: SkillLevel.intermediate,
        minParticipants: 10,
        maxParticipants: 14,
        status: MatchStatus.open,
        recruitmentMode: RecruitmentMode.players,
        createdAt: now,
        updatedAt: now,
        acceptedCount: 9,
      ),
      Match(
        id: 'm2',
        organizerId: 'other-user',
        sportId: 'basquetbol',
        title: 'Básquet 3x3 nocturno',
        description: 'Media cancha, nivel relajado.',
        startAt: now.add(const Duration(days: 1, hours: 8)),
        commune: 'Ñuñoa',
        locationText: 'Plaza Ñuñoa',
        skillLevel: SkillLevel.beginner,
        minParticipants: 6,
        maxParticipants: 6,
        status: MatchStatus.open,
        recruitmentMode: RecruitmentMode.players,
        createdAt: now,
        updatedAt: now,
        acceptedCount: 4,
      ),
      Match(
        id: 'm3',
        organizerId: 'other-user',
        sportId: 'padel',
        title: 'Pádel dobles avanzado',
        description: 'Buscamos una pareja rival de buen nivel.',
        startAt: now.add(const Duration(days: 3, hours: 1)),
        commune: 'Las Condes',
        locationText: 'Club de Pádel El Golf',
        skillLevel: SkillLevel.advanced,
        minParticipants: 4,
        maxParticipants: 4,
        status: MatchStatus.open,
        recruitmentMode: RecruitmentMode.players,
        createdAt: now,
        updatedAt: now,
        acceptedCount: 2,
      ),
    ]);
  }

  @override
  Future<List<Match>> searchMatches(MatchFilter filter) async {
    await _tick();
    return _matches.where((m) {
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
    }).toList()
      ..sort((a, b) => a.startAt.compareTo(b.startAt));
  }

  @override
  Future<Match?> getMatch(String id) async {
    await _tick();
    try {
      return _matches.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Match> createMatch(Match match) async {
    await _tick();
    final id = 'local-${++_counter}';
    final now = DateTime.now();
    final created = Match(
      id: id,
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
    _matches.add(created);
    return created;
  }

  @override
  Future<Match> updateMatch(Match match) async {
    await _tick();
    final i = _matches.indexWhere((m) => m.id == match.id);
    if (i == -1) throw StateError('Match no encontrado');
    final updated = match.copyWith(updatedAt: DateTime.now());
    _matches[i] = updated;
    return updated;
  }

  @override
  Future<void> updateStatus(String matchId, MatchStatus status) async {
    await _tick();
    final i = _matches.indexWhere((m) => m.id == matchId);
    if (i == -1) return;
    _matches[i] = _matches[i].copyWith(status: status);
  }

  @override
  Future<List<Match>> getMyOrganizedMatches(String userId) async {
    await _tick();
    return _matches.where((m) => m.organizerId == userId).toList();
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
