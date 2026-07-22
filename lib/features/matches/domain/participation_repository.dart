import '../../../core/domain/enums.dart';
import 'match_participation.dart';

/// Contrato de solicitudes y asistencia a partidos.
abstract interface class ParticipationRepository {
  /// Participantes y solicitudes de un partido (vista del organizador).
  Future<List<MatchParticipation>> getParticipantsForMatch(String matchId);

  /// Participaciones del usuario en cualquier partido (pantalla "Mis
  /// participaciones").
  Future<List<MatchParticipation>> getMyParticipations(String userId);

  /// Envía una solicitud `pending` para incorporarse a un partido (Flujo B).
  Future<MatchParticipation> requestToJoin({
    required String matchId,
    required String userId,
  });

  /// El organizador acepta o rechaza una solicitud.
  Future<void> respondToRequest({
    required String participationId,
    required bool accept,
  });

  /// Un participante aceptado confirma o rechaza su asistencia.
  Future<void> setAttendance({
    required String participationId,
    required AttendanceStatus status,
  });

  /// El usuario abandona/cancela su propia participación.
  Future<void> cancelParticipation(String participationId);
}
