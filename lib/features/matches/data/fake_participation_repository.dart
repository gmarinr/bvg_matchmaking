import '../../../core/domain/enums.dart';
import '../domain/match_participation.dart';
import '../domain/participation_repository.dart';

/// Implementación en memoria de solicitudes y asistencia.
class FakeParticipationRepository implements ParticipationRepository {
  final List<MatchParticipation> _rows = [];
  int _counter = 0;

  @override
  Future<List<MatchParticipation>> getParticipantsForMatch(
      String matchId) async {
    await _tick();
    return _rows.where((p) => p.matchId == matchId).toList();
  }

  @override
  Future<List<MatchParticipation>> getMyParticipations(String userId) async {
    await _tick();
    return _rows.where((p) => p.userId == userId).toList();
  }

  @override
  Future<MatchParticipation> requestToJoin({
    required String matchId,
    required String userId,
  }) async {
    await _tick();
    final existing = _rows.any((p) => p.matchId == matchId && p.userId == userId);
    if (existing) {
      throw StateError('Ya solicitaste participar en este partido.');
    }
    final now = DateTime.now();
    final row = MatchParticipation(
      id: 'part-${++_counter}',
      matchId: matchId,
      userId: userId,
      role: ParticipantRole.participant,
      participationStatus: ParticipationStatus.pending,
      attendanceStatus: AttendanceStatus.unknown,
      createdAt: now,
      updatedAt: now,
    );
    _rows.add(row);
    return row;
  }

  @override
  Future<void> respondToRequest({
    required String participationId,
    required bool accept,
  }) async {
    await _tick();
    final i = _rows.indexWhere((p) => p.id == participationId);
    if (i == -1) return;
    _rows[i] = _rows[i].copyWith(
      participationStatus:
          accept ? ParticipationStatus.accepted : ParticipationStatus.rejected,
    );
  }

  @override
  Future<void> setAttendance({
    required String participationId,
    required AttendanceStatus status,
  }) async {
    await _tick();
    final i = _rows.indexWhere((p) => p.id == participationId);
    if (i == -1) return;
    _rows[i] = _rows[i].copyWith(attendanceStatus: status);
  }

  @override
  Future<void> cancelParticipation(String participationId) async {
    await _tick();
    final i = _rows.indexWhere((p) => p.id == participationId);
    if (i == -1) return;
    _rows[i] = _rows[i].copyWith(
      participationStatus: ParticipationStatus.cancelled,
    );
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
