import 'enums.dart';

/// Deporte del catálogo controlado (`sports`). No se crea libremente desde
/// la app: proviene de datos semilla.
class Sport {
  const Sport({required this.id, required this.name, this.isActive = true});

  final String id;
  final String name;
  final bool isActive;

  factory Sport.fromJson(Map<String, dynamic> json) => Sport(
    id: json['id'] as String,
    name: json['name'] as String,
    isActive: json['is_active'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'is_active': isActive,
  };
}

/// Relación usuario–deporte–nivel (`user_sports`).
class UserSport {
  const UserSport({
    required this.userId,
    required this.sportId,
    required this.skillLevel,
  });

  final String userId;
  final String sportId;
  final SkillLevel skillLevel;

  factory UserSport.fromJson(Map<String, dynamic> json) => UserSport(
    userId: json['user_id'] as String,
    sportId: json['sport_id'] as String,
    skillLevel: SkillLevel.fromWire(json['skill_level'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'sport_id': sportId,
    'skill_level': skillLevel.wire,
  };
}
