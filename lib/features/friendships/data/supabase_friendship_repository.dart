import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_error_mapper.dart';
import '../../../core/errors/failures.dart';
import '../domain/friendship.dart';
import '../domain/friendship_repository.dart';

class SupabaseFriendshipRepository implements FriendshipRepository {
  SupabaseFriendshipRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Friendship?> getBetween({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final direct = await _client
          .from('friendships')
          .select()
          .eq('requester_id', currentUserId)
          .eq('addressee_id', otherUserId)
          .inFilter('status', ['pending', 'accepted'])
          .maybeSingle();
      if (direct != null) return Friendship.fromJson(_asMap(direct));

      final reverse = await _client
          .from('friendships')
          .select()
          .eq('requester_id', otherUserId)
          .eq('addressee_id', currentUserId)
          .inFilter('status', ['pending', 'accepted'])
          .maybeSingle();
      return reverse == null ? null : Friendship.fromJson(_asMap(reverse));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<Friendship> sendRequest({
    required String requesterId,
    required String addresseeId,
  }) async {
    try {
      final row = await _client
          .from('friendships')
          .insert({
            'requester_id': requesterId,
            'addressee_id': addresseeId,
            'status': FriendshipStatus.pending.wire,
          })
          .select()
          .single();
      return Friendship.fromJson(_asMap(row));
    } on PostgrestException catch (error) {
      if (error.code == '23505') {
        throw const ValidationFailure(
          'Ya existe una solicitud o amistad activa con esta persona.',
        );
      }
      throw mapSupabaseError(error);
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static Map<String, dynamic> _asMap(Object value) =>
      Map<String, dynamic>.from(value as Map);
}
