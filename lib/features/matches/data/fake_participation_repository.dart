import '../../../core/domain/enums.dart';
import '../domain/match_participation.dart';
import '../domain/participation_repository.dart';
import 'in_memory_match_store.dart';

/// Implementación en memoria de solicitudes y asistencia. Cada cambio de
/// estado repercute en los cupos y el estado del partido a través del store.
class FakeParticipationRepository implements ParticipationRepository {
  FakeParticipationRepository(this._store);

  final InMemoryMatchStore _store;

  @override
  Future<List<MatchParticipation>> getParticipantsForMatch(
    String matchId,
  ) async {
    await _tick();
    return _store.participations.where((p) => p.matchId == matchId).toList();
  }

  @override
  Future<List<MatchParticipation>> getMyParticipations(String userId) async {
    await _tick();
    return _store.participations.where((p) => p.userId == userId).toList();
  }

  @override
  Future<MatchParticipation> requestToJoin({
    required String matchId,
    required String userId,
  }) async {
    await _tick();
    final existingIndex = _store.participations.indexWhere(
      (p) => p.matchId == matchId && p.userId == userId,
    );
    if (existingIndex != -1) {
      final existing = _store.participations[existingIndex];
      final active =
          existing.participationStatus == ParticipationStatus.pending ||
          existing.participationStatus == ParticipationStatus.accepted;
      if (active) {
        throw StateError('Ya solicitaste participar en este partido.');
      }
      // Quien salió (cancelada) o fue rechazado puede volver a solicitar: se
      // reactiva la misma fila como una nueva solicitud pendiente.
      final reactivated = existing.copyWith(
        participationStatus: ParticipationStatus.pending,
        attendanceStatus: AttendanceStatus.unknown,
        updatedAt: DateTime.now(),
      );
      _store.participations[existingIndex] = reactivated;
      return reactivated;
    }

    final now = DateTime.now();
    final row = MatchParticipation(
      id: _store.nextId('part'),
      matchId: matchId,
      userId: userId,
      role: ParticipantRole.participant,
      participationStatus: ParticipationStatus.pending,
      attendanceStatus: AttendanceStatus.unknown,
      createdAt: now,
      updatedAt: now,
    );
    _store.participations.add(row);
    return row;
  }

  @override
  Future<void> respondToRequest({
    required String participationId,
    required bool accept,
  }) async {
    await _tick();
    _transition(
      participationId,
      accept ? ParticipationStatus.accepted : ParticipationStatus.rejected,
    );
  }

  @override
  Future<void> setAttendance({
    required String participationId,
    required AttendanceStatus status,
  }) async {
    await _tick();
    final i = _indexOf(participationId);
    if (i == -1) return;
    _store.participations[i] = _store.participations[i].copyWith(
      attendanceStatus: status,
    );
  }

  @override
  Future<void> cancelParticipation(String participationId) async {
    await _tick();
    _transition(participationId, ParticipationStatus.cancelled);
  }

  /// Cambia el estado de la participación y actualiza cupos/estado del partido.
  void _transition(String participationId, ParticipationStatus to) {
    final i = _indexOf(participationId);
    if (i == -1) return;
    final row = _store.participations[i];
    final from = row.participationStatus;
    if (from == to) return;

    _store.participations[i] = row.copyWith(participationStatus: to);
    _store.applyParticipationChange(matchId: row.matchId, from: from, to: to);
  }

  int _indexOf(String participationId) =>
      _store.participations.indexWhere((p) => p.id == participationId);

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
