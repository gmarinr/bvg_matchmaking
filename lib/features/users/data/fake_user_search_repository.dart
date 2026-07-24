import '../../../core/domain/enums.dart';
import '../domain/public_user_profile.dart';
import '../domain/user_search_repository.dart';

class FakeUserSearchRepository implements UserSearchRepository {
  static const demoUserId = '11111111-1111-4111-8111-111111111111';

  static PublicUserProfile _profile(
    String id,
    String name,
    String commune,
    List<PublicUserSport> sports,
  ) => PublicUserProfile(
    id: id,
    displayName: name,
    commune: commune,
    sports: sports,
  );

  static PublicUserSport _sport(String id, String name, SkillLevel level) =>
      PublicUserSport(sportId: id, sportName: name, skillLevel: level);

  /// Perfiles públicos de los usuarios demo. Coinciden con los perfiles semilla
  /// del resto de la app, para que las tarjetas de amigos y participantes
  /// muestren nombres reales y puedan abrir el perfil.
  static final Map<String, PublicUserProfile> _profiles = {
    demoUserId: _profile(demoUserId, 'Camila Rojas', 'La Reina', [
      _sport('futbol', 'Fútbol', SkillLevel.intermediate),
      _sport('tenis', 'Tenis', SkillLevel.beginner),
    ]),
    'fake-user-1': _profile('fake-user-1', 'Tu perfil', 'Santiago', [
      _sport('futbol', 'Fútbol', SkillLevel.intermediate),
    ]),
    'other-user': _profile('other-user', 'Camila Rojas', 'La Reina', [
      _sport('futbol', 'Fútbol', SkillLevel.intermediate),
    ]),
    'user-a': _profile('user-a', 'Diego Fuentes', 'Maipú', [
      _sport('voleibol', 'Vóleibol', SkillLevel.beginner),
      _sport('basquetbol', 'Básquetbol', SkillLevel.intermediate),
    ]),
    'user-b': _profile('user-b', 'Valentina Soto', 'Estación Central', [
      _sport('voleibol', 'Vóleibol', SkillLevel.intermediate),
    ]),
    'user-c': _profile('user-c', 'Matías Herrera', 'Maipú', [
      _sport('voleibol', 'Vóleibol', SkillLevel.advanced),
    ]),
    'user-d': _profile('user-d', 'Josefa Lagos', 'La Reina', [
      _sport('futbol', 'Fútbol', SkillLevel.beginner),
    ]),
    'user-e': _profile('user-e', 'Ignacio Peña', 'Peñalolén', [
      _sport('tenis', 'Tenis', SkillLevel.advanced),
    ]),
  };

  @override
  Future<PublicUserProfile?> findById(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _profiles[userId];
  }
}
