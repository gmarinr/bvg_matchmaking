import '../../../core/domain/enums.dart';
import '../domain/public_user_profile.dart';
import '../domain/user_search_repository.dart';

class FakeUserSearchRepository implements UserSearchRepository {
  static const demoUserId = '11111111-1111-4111-8111-111111111111';

  static const _profiles = <String, PublicUserProfile>{
    demoUserId: PublicUserProfile(
      id: demoUserId,
      displayName: 'Camila Rojas',
      commune: 'La Reina',
      sports: [
        PublicUserSport(
          sportId: 'futbol',
          sportName: 'Fútbol',
          skillLevel: SkillLevel.intermediate,
        ),
        PublicUserSport(
          sportId: 'tenis',
          sportName: 'Tenis',
          skillLevel: SkillLevel.beginner,
        ),
      ],
    ),
  };

  @override
  Future<PublicUserProfile?> findById(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _profiles[userId];
  }
}
