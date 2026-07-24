/// Perfil deportivo del usuario (`profiles`). Extiende al usuario autenticado.
class Profile {
  const Profile({
    required this.id,
    required this.displayName,
    required this.commune,
    this.communeCode,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.generalAvailability,
  });

  final String id;
  final String displayName;
  final String commune;
  final String? communeCode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;
  final String? generalAvailability;

  Profile copyWith({
    String? displayName,
    String? commune,
    String? communeCode,
    String? avatarUrl,
    String? generalAvailability,
    DateTime? updatedAt,
  }) => Profile(
    id: id,
    displayName: displayName ?? this.displayName,
    commune: commune ?? this.commune,
    communeCode: communeCode ?? this.communeCode,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    avatarUrl: avatarUrl ?? this.avatarUrl,
    generalAvailability: generalAvailability ?? this.generalAvailability,
  );

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id: json['id'] as String,
    displayName: json['display_name'] as String,
    commune: json['commune'] as String,
    communeCode: json['commune_code'] as String?,
    createdAt: DateTime.parse(json['created_at'] as String),
    updatedAt: DateTime.parse(json['updated_at'] as String),
    avatarUrl: json['avatar_url'] as String?,
    generalAvailability: json['general_availability'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'display_name': displayName,
    'commune': commune,
    'commune_code': communeCode,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'avatar_url': avatarUrl,
    'general_availability': generalAvailability,
  };
}
