import '../../../core/domain/sport.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

/// Implementación en memoria del perfil y el catálogo de deportes.
class FakeProfileRepository implements ProfileRepository {
  final Map<String, Profile> _profiles = {..._seedProfiles};
  final List<UserSport> _userSports = [];

  static final DateTime _seedDate = DateTime(2026, 7, 1);

  static Profile _profile(String id, String name, String commune) => Profile(
    id: id,
    displayName: name,
    commune: commune,
    createdAt: _seedDate,
    updatedAt: _seedDate,
  );

  /// Perfiles de los usuarios que aparecen en los datos semilla, para que la
  /// gestión de solicitudes muestre nombres y no identificadores.
  static final Map<String, Profile> _seedProfiles = {
    'fake-user-1': _profile('fake-user-1', 'Tu perfil', 'Santiago'),
    'other-user': _profile('other-user', 'Camila Rojas', 'La Reina'),
    'user-a': _profile('user-a', 'Diego Fuentes', 'Maipú'),
    'user-b': _profile('user-b', 'Valentina Soto', 'Estación Central'),
    'user-c': _profile('user-c', 'Matías Herrera', 'Maipú'),
    'user-d': _profile('user-d', 'Josefa Lagos', 'La Reina'),
    'user-e': _profile('user-e', 'Ignacio Peña', 'Peñalolén'),
  };

  static const List<Sport> _seedSports = [
    Sport(id: 'futbol', name: 'Fútbol'),
    Sport(id: 'basquetbol', name: 'Básquetbol'),
    Sport(id: 'tenis', name: 'Tenis'),
    Sport(id: 'padel', name: 'Pádel'),
    Sport(id: 'voleibol', name: 'Vóleibol'),
  ];

  @override
  Future<Profile?> getProfile(String userId) async {
    await _tick();
    return _profiles[userId];
  }

  @override
  Future<Profile> upsertProfile(Profile profile) async {
    await _tick();
    final saved = profile.copyWith(updatedAt: DateTime.now());
    _profiles[profile.id] = saved;
    return saved;
  }

  @override
  Future<List<Sport>> getSports() async {
    await _tick();
    return _seedSports.where((s) => s.isActive).toList();
  }

  @override
  Future<List<UserSport>> getUserSports(String userId) async {
    await _tick();
    return _userSports.where((us) => us.userId == userId).toList();
  }

  @override
  Future<void> setUserSport(UserSport userSport) async {
    await _tick();
    _userSports.removeWhere(
      (us) => us.userId == userSport.userId && us.sportId == userSport.sportId,
    );
    _userSports.add(userSport);
  }

  @override
  Future<void> removeUserSport({
    required String userId,
    required String sportId,
  }) async {
    await _tick();
    _userSports.removeWhere(
      (us) => us.userId == userId && us.sportId == sportId,
    );
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 300));
}
