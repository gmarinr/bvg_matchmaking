import '../../../core/domain/enums.dart';
import '../domain/match.dart';
import '../domain/match_participation.dart';

/// Almacén en memoria compartido por los repositorios falsos de partidos y
/// participaciones, para que aceptar o rechazar una solicitud repercuta en los
/// cupos y el estado del partido.
///
/// La semántica de [applyParticipationChange] es la que debe replicar la
/// implementación real contra la base de datos.
class InMemoryMatchStore {
  InMemoryMatchStore() {
    _seed();
  }

  final List<Match> matches = [];
  final List<MatchParticipation> participations = [];

  int _seq = 0;
  String nextId(String prefix) => '$prefix-${++_seq}';

  Match? findMatch(String id) {
    for (final m in matches) {
      if (m.id == id) return m;
    }
    return null;
  }

  /// Ajusta cupos ocupados y estado del partido ante un cambio de estado de
  /// una participación.
  ///
  /// - Solo las participaciones `accepted` ocupan cupo.
  /// - Al llegar al máximo, el partido pasa a `full`.
  /// - Si se libera un cupo y seguía `full`, vuelve a `open`.
  void applyParticipationChange({
    required String matchId,
    required ParticipationStatus from,
    required ParticipationStatus to,
  }) {
    final i = matches.indexWhere((m) => m.id == matchId);
    if (i == -1) return;
    final match = matches[i];

    final wasAccepted = from == ParticipationStatus.accepted;
    final isAccepted = to == ParticipationStatus.accepted;
    if (wasAccepted == isAccepted) return;

    var count = match.acceptedCount + (isAccepted ? 1 : -1);
    count = count.clamp(0, match.maxParticipants);

    var status = match.status;
    if (status == MatchStatus.open && count >= match.maxParticipants) {
      status = MatchStatus.full;
    } else if (status == MatchStatus.full && count < match.maxParticipants) {
      status = MatchStatus.open;
    }

    matches[i] = match.copyWith(
      acceptedCount: count,
      status: status,
      updatedAt: DateTime.now(),
    );
  }

  void _seed() {
    final now = DateTime.now();

    matches.addAll([
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
      // Partido organizado por el usuario de la sesión falsa, con solicitudes
      // pendientes para poder ejercitar la gestión del organizador.
      Match(
        id: 'm4',
        organizerId: 'fake-user-1',
        sportId: 'voleibol',
        title: 'Vóleibol en Maipú',
        description: 'Cancha techada, llevamos las pelotas.',
        startAt: now.add(const Duration(days: 4, hours: 2)),
        commune: 'Maipú',
        locationText: 'Gimnasio Municipal',
        skillLevel: SkillLevel.beginner,
        // Mínimo alcanzable aceptando las dos solicitudes pendientes: así se
        // puede recorrer el flujo completo hasta confirmar el partido.
        minParticipants: 4,
        maxParticipants: 12,
        status: MatchStatus.open,
        recruitmentMode: RecruitmentMode.players,
        createdAt: now,
        updatedAt: now,
        acceptedCount: 2,
      ),
    ]);

    participations.addAll([
      _row('p1', 'm4', 'fake-user-1', ParticipantRole.organizer,
          ParticipationStatus.accepted, now),
      _row('p2', 'm4', 'user-c', ParticipantRole.participant,
          ParticipationStatus.accepted, now),
      _row('p3', 'm4', 'user-a', ParticipantRole.participant,
          ParticipationStatus.pending, now),
      _row('p4', 'm4', 'user-b', ParticipantRole.participant,
          ParticipationStatus.pending, now),
      _row('p5', 'm1', 'user-d', ParticipantRole.participant,
          ParticipationStatus.pending, now),
      _row('p6', 'm1', 'user-e', ParticipantRole.participant,
          ParticipationStatus.pending, now),
    ]);
  }

  MatchParticipation _row(
    String id,
    String matchId,
    String userId,
    ParticipantRole role,
    ParticipationStatus status,
    DateTime now,
  ) =>
      MatchParticipation(
        id: id,
        matchId: matchId,
        userId: userId,
        role: role,
        participationStatus: status,
        attendanceStatus: AttendanceStatus.unknown,
        createdAt: now,
        updatedAt: now,
      );
}
