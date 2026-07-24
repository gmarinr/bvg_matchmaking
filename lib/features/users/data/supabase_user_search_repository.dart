import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_error_mapper.dart';
import '../domain/public_user_profile.dart';
import '../domain/user_search_repository.dart';

class SupabaseUserSearchRepository implements UserSearchRepository {
  SupabaseUserSearchRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<PublicUserProfile?> findById(String userId) async {
    try {
      final result = await _client.rpc(
        'find_public_profile_by_id',
        params: {'p_user_id': userId},
      );
      if (result is! List || result.isEmpty) return null;
      return PublicUserProfile.fromJson(
        Map<String, dynamic>.from(result.first as Map),
      );
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }
}
