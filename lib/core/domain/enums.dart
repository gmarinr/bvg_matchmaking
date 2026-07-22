/// Enums del dominio — fuente única de verdad.
///
/// Cada valor `wire` DEBE coincidir 1:1 con el tipo `enum` correspondiente
/// en PostgreSQL. Si cambias un valor aquí, actualiza también la migración
/// SQL en el mismo PR y avisa al equipo: frontend y BBDD dependen de esto.
library;

/// Ciclo de vida del partido — `match_status`.
enum MatchStatus {
  draft('draft'),
  open('open'),
  full('full'),
  confirmed('confirmed'),
  completed('completed'),
  cancelled('cancelled');

  const MatchStatus(this.wire);
  final String wire;

  static MatchStatus fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Objetivo de convocatoria — `recruitment_mode`.
/// `rivalTeam` queda reservado para una versión futura; el MVP usa `players`.
enum RecruitmentMode {
  players('players'),
  rivalTeam('rival_team');

  const RecruitmentMode(this.wire);
  final String wire;

  static RecruitmentMode fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Estado de la solicitud de participación — `participation_status`.
enum ParticipationStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  cancelled('cancelled');

  const ParticipationStatus(this.wire);
  final String wire;

  static ParticipationStatus fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Confirmación de asistencia — `attendance_status`.
enum AttendanceStatus {
  unknown('unknown'),
  confirmed('confirmed'),
  declined('declined');

  const AttendanceStatus(this.wire);
  final String wire;

  static AttendanceStatus fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Rol del usuario dentro de un partido — columna `role`.
enum ParticipantRole {
  organizer('organizer'),
  participant('participant');

  const ParticipantRole(this.wire);
  final String wire;

  static ParticipantRole fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}

/// Nivel deportivo autodeclarado — `skill_level`.
enum SkillLevel {
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const SkillLevel(this.wire);
  final String wire;

  static SkillLevel fromWire(String value) =>
      values.firstWhere((e) => e.wire == value);
}
