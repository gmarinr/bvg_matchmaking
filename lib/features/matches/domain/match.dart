import '../../../core/domain/enums.dart';

/// Partido deportivo (`matches`). Unidad central del sistema.
class Match {
  const Match({
    required this.id,
    required this.organizerId,
    required this.sportId,
    required this.title,
    required this.startAt,
    required this.commune,
    this.communeCode,
    required this.locationText,
    required this.skillLevel,
    required this.minParticipants,
    required this.maxParticipants,
    required this.status,
    required this.recruitmentMode,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.acceptedCount = 0,
  });

  final String id;
  final String organizerId;
  final String sportId;
  final String title;
  final String? description;
  final DateTime startAt;
  final String commune;
  final String? communeCode;
  final String locationText;
  final SkillLevel skillLevel;
  final int minParticipants;
  final int maxParticipants;
  final MatchStatus status;
  final RecruitmentMode recruitmentMode;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Cupos ocupados por participantes aceptados. Derivado; el backend puede
  /// enviarlo agregado. En la UI sirve para mostrar "X / Y jugadores".
  final int acceptedCount;

  int get freeSlots =>
      (maxParticipants - acceptedCount).clamp(0, maxParticipants);
  bool get isJoinable => status == MatchStatus.open && freeSlots > 0;

  Match copyWith({
    String? title,
    String? description,
    DateTime? startAt,
    String? commune,
    String? communeCode,
    String? locationText,
    SkillLevel? skillLevel,
    int? minParticipants,
    int? maxParticipants,
    MatchStatus? status,
    int? acceptedCount,
    DateTime? updatedAt,
  }) => Match(
    id: id,
    organizerId: organizerId,
    sportId: sportId,
    title: title ?? this.title,
    description: description ?? this.description,
    startAt: startAt ?? this.startAt,
    commune: commune ?? this.commune,
    communeCode: communeCode ?? this.communeCode,
    locationText: locationText ?? this.locationText,
    skillLevel: skillLevel ?? this.skillLevel,
    minParticipants: minParticipants ?? this.minParticipants,
    maxParticipants: maxParticipants ?? this.maxParticipants,
    status: status ?? this.status,
    recruitmentMode: recruitmentMode,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    acceptedCount: acceptedCount ?? this.acceptedCount,
  );

  factory Match.fromJson(Map<String, dynamic> json) => Match(
    id: json['id'] as String,
    organizerId: json['organizer_id'] as String,
    sportId: json['sport_id'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    startAt: DateTime.parse(json['start_at'] as String),
    commune: json['commune'] as String,
    communeCode: json['commune_code'] as String?,
    locationText: json['location_text'] as String,
    skillLevel: SkillLevel.fromWire(json['skill_level'] as String),
    minParticipants: json['min_participants'] as int,
    maxParticipants: json['max_participants'] as int,
    status: MatchStatus.fromWire(json['status'] as String),
    recruitmentMode: RecruitmentMode.fromWire(
      json['recruitment_mode'] as String,
    ),
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    acceptedCount: json['accepted_count'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'organizer_id': organizerId,
    'sport_id': sportId,
    'title': title,
    'description': description,
    'start_at': startAt.toIso8601String(),
    'commune': commune,
    'commune_code': communeCode,
    'location_text': locationText,
    'skill_level': skillLevel.wire,
    'min_participants': minParticipants,
    'max_participants': maxParticipants,
    'status': status.wire,
    'recruitment_mode': recruitmentMode.wire,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

/// Criterios de búsqueda de partidos (Flujo B). Todos opcionales.
class MatchFilter {
  const MatchFilter({
    this.sportId,
    this.commune,
    this.skillLevel,
    this.fromDate,
  });

  final String? sportId;
  final String? commune;
  final SkillLevel? skillLevel;
  final DateTime? fromDate;

  bool get isEmpty =>
      sportId == null &&
      (commune == null || commune!.isEmpty) &&
      skillLevel == null &&
      fromDate == null;

  MatchFilter copyWith({
    String? sportId,
    String? commune,
    SkillLevel? skillLevel,
    DateTime? fromDate,
    bool clearSport = false,
    bool clearCommune = false,
    bool clearSkill = false,
    bool clearDate = false,
  }) => MatchFilter(
    sportId: clearSport ? null : (sportId ?? this.sportId),
    commune: clearCommune ? null : (commune ?? this.commune),
    skillLevel: clearSkill ? null : (skillLevel ?? this.skillLevel),
    fromDate: clearDate ? null : (fromDate ?? this.fromDate),
  );
}
