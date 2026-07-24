import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_error_mapper.dart';
import '../../../core/errors/failures.dart';
import '../domain/friendship.dart';
import '../domain/friendship_repository.dart';

class SupabaseFriendshipRepository implements FriendshipRepository {
  SupabaseFriendshipRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Friendship>> getReceivedPending(String userId) async {
    try {
      final rows = await _client
          .from('friendships')
          .select()
          .eq('addressee_id', userId)
          .eq('status', FriendshipStatus.pending.wire)
          .order('updated_at', ascending: false);
      return _asList(rows).map(Friendship.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<Friendship>> getSentPending(String userId) async {
    try {
      final rows = await _client
          .from('friendships')
          .select()
          .eq('requester_id', userId)
          .eq('status', FriendshipStatus.pending.wire)
          .order('updated_at', ascending: false);
      return _asList(rows).map(Friendship.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<Friendship>> getAccepted(String userId) async {
    try {
      final requested = await _client
          .from('friendships')
          .select()
          .eq('requester_id', userId)
          .eq('status', FriendshipStatus.accepted.wire)
          .order('updated_at', ascending: false);
      final received = await _client
          .from('friendships')
          .select()
          .eq('addressee_id', userId)
          .eq('status', FriendshipStatus.accepted.wire)
          .order('updated_at', ascending: false);
      return [
        ..._asList(requested).map(Friendship.fromJson),
        ..._asList(received).map(Friendship.fromJson),
      ];
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

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

  @override
  Future<Friendship> acceptRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.accepted);

  @override
  Future<Friendship> rejectRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.rejected);

  @override
  Future<Friendship> cancelRequest(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.cancelled);

  @override
  Future<Friendship> removeFriendship(String friendshipId) =>
      _changeStatus(friendshipId, FriendshipStatus.cancelled);

  Future<Friendship> _changeStatus(
    String friendshipId,
    FriendshipStatus status,
  ) async {
    try {
      final row = await _client
          .from('friendships')
          .update({'status': status.wire})
          .eq('id', friendshipId)
          .select()
          .single();
      return Friendship.fromJson(_asMap(row));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static Map<String, dynamic> _asMap(dynamic value) =>
      Map<String, dynamic>.from(value as Map);

  static List<Map<String, dynamic>> _asList(dynamic value) =>
      (value as List)
          .map<Map<String, dynamic>>((item) => _asMap(item))
          .toList();
}
