import 'public_user_profile.dart';

abstract interface class UserSearchRepository {
  /// Busca un único perfil público por UUID exacto.
  Future<PublicUserProfile?> findById(String userId);
}
