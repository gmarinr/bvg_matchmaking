import '../../../core/domain/enums.dart';

/// Participación de un usuario en un partido (`match_participations`).
/// Una fila por combinación única `match_id + user_id`.
class MatchParticipation {
  const MatchParticipation({
    required this.id,
    required this.matchId,
    required this.userId,
    required this.role,
    required this.participationStatus,
    required this.attendanceStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String matchId;
  final String userId;
  final ParticipantRole role;
  final ParticipationStatus participationStatus;
  final AttendanceStatus attendanceStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOrganizer => role == ParticipantRole.organizer;
  bool get isAccepted => participationStatus == ParticipationStatus.accepted;
  bool get canConfirmAttendance => isAccepted;

  MatchParticipation copyWith({
    ParticipationStatus? participationStatus,
    AttendanceStatus? attendanceStatus,
    DateTime? updatedAt,
  }) => MatchParticipation(
    id: id,
    matchId: matchId,
    userId: userId,
    role: role,
    participationStatus: participationStatus ?? this.participationStatus,
    attendanceStatus: attendanceStatus ?? this.attendanceStatus,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  factory MatchParticipation.fromJson(Map<String, dynamic> json) =>
      MatchParticipation(
        id: json['id'] as String,
        matchId: json['match_id'] as String,
        userId: json['user_id'] as String,
        role: ParticipantRole.fromWire(json['role'] as String),
        participationStatus: ParticipationStatus.fromWire(
          json['participation_status'] as String,
        ),
        attendanceStatus: AttendanceStatus.fromWire(
          json['attendance_status'] as String,
        ),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'match_id': matchId,
    'user_id': userId,
    'role': role.wire,
    'participation_status': participationStatus.wire,
    'attendance_status': attendanceStatus.wire,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
