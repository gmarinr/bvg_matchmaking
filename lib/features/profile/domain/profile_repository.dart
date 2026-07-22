import '../../../core/domain/sport.dart';
import 'profile.dart';

/// Contrato de perfil deportivo y catálogo de deportes.
abstract interface class ProfileRepository {
  /// Perfil de un usuario, o `null` si aún no lo ha creado.
  Future<Profile?> getProfile(String userId);

  /// Crea o actualiza el perfil (upsert por `id`).
  Future<Profile> upsertProfile(Profile profile);

  /// Catálogo de deportes activos (datos semilla).
  Future<List<Sport>> getSports();

  /// Deportes y niveles declarados por el usuario.
  Future<List<UserSport>> getUserSports(String userId);

  /// Declara o actualiza el nivel del usuario en un deporte.
  Future<void> setUserSport(UserSport userSport);

  /// Quita un deporte declarado por el usuario.
  Future<void> removeUserSport({
    required String userId,
    required String sportId,
  });
}
