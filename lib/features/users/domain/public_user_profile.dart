import '../../../core/domain/enums.dart';

/// Perfil mínimo que puede verse al buscar un UUID exacto.
/// No contiene correo, disponibilidad ni datos de autenticación.
class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.displayName,
    required this.commune,
    required this.sports,
  });

  final String id;
  final String displayName;
  final String commune;
  final List<PublicUserSport> sports;

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    final rawSports = json['sports'];
    final sports = rawSports is List
        ? rawSports
              .whereType<Map>()
              .map(
                (sport) => PublicUserSport.fromJson(
                  Map<String, dynamic>.from(sport),
                ),
              )
              .toList()
        : <PublicUserSport>[];

    return PublicUserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String? ?? '',
      commune: json['commune'] as String? ?? '',
      sports: sports,
    );
  }
}

class PublicUserSport {
  const PublicUserSport({
    required this.sportId,
    required this.sportName,
    required this.skillLevel,
  });

  final String sportId;
  final String sportName;
  final SkillLevel skillLevel;

  factory PublicUserSport.fromJson(Map<String, dynamic> json) =>
      PublicUserSport(
        sportId: json['id'] as String,
        sportName: json['name'] as String,
        skillLevel: SkillLevel.fromWire(json['skill_level'] as String),
      );
}
