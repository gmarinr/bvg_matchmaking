import '../domain/enums.dart';

/// Etiquetas en español para los enums del dominio (capa de presentación).
extension SkillLevelLabel on SkillLevel {
  String get label => switch (this) {
    SkillLevel.beginner => 'Principiante',
    SkillLevel.intermediate => 'Intermedio',
    SkillLevel.advanced => 'Avanzado',
  };
}

extension MatchStatusLabel on MatchStatus {
  String get label => switch (this) {
    MatchStatus.draft => 'Borrador',
    MatchStatus.open => 'Abierto',
    MatchStatus.full => 'Completo',
    MatchStatus.confirmed => 'Confirmado',
    MatchStatus.completed => 'Finalizado',
    MatchStatus.cancelled => 'Cancelado',
  };
}

extension ParticipationStatusLabel on ParticipationStatus {
  String get label => switch (this) {
    ParticipationStatus.pending => 'Pendiente',
    ParticipationStatus.accepted => 'Aceptado',
    ParticipationStatus.rejected => 'Rechazado',
    ParticipationStatus.cancelled => 'Cancelado',
  };
}

extension AttendanceStatusLabel on AttendanceStatus {
  String get label => switch (this) {
    AttendanceStatus.unknown => 'Sin confirmar',
    AttendanceStatus.confirmed => 'Confirmada',
    AttendanceStatus.declined => 'No asistirá',
  };
}
