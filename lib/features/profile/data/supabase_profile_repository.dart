import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/sport.dart';
import '../../../core/supabase/supabase_error_mapper.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

/// Supabase adapter for profiles, sports and user sports.
class SupabaseProfileRepository implements ProfileRepository {
  SupabaseProfileRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Profile?> getProfile(String userId) async {
    try {
      final row = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      return row == null ? null : Profile.fromJson(_asMap(row));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<Profile> upsertProfile(Profile profile) async {
    try {
      final payload = {
        'id': profile.id,
        'display_name': profile.displayName,
        'commune': profile.commune,
        'avatar_url': profile.avatarUrl,
        'general_availability': profile.generalAvailability,
      };
      final row = await _client
          .from('profiles')
          .upsert(payload, onConflict: 'id')
          .select()
          .single();
      return Profile.fromJson(_asMap(row));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<Sport>> getSports() async {
    try {
      final rows = await _client
          .from('sports')
          .select()
          .eq('is_active', true)
          .order('name');
      return _asList(rows).map(Sport.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<UserSport>> getUserSports(String userId) async {
    try {
      final rows = await _client
          .from('user_sports')
          .select()
          .eq('user_id', userId)
          .order('sport_id');
      return _asList(rows).map(UserSport.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> setUserSport(UserSport userSport) async {
    try {
      await _client
          .from('user_sports')
          .upsert(userSport.toJson(), onConflict: 'user_id,sport_id');
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> removeUserSport({
    required String userId,
    required String sportId,
  }) async {
    try {
      await _client
          .from('user_sports')
          .delete()
          .eq('user_id', userId)
          .eq('sport_id', sportId);
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static Map<String, dynamic> _asMap(Object value) =>
      Map<String, dynamic>.from(value as Map);

  static List<Map<String, dynamic>> _asList(Object value) =>
      (value as List).map((row) => _asMap(row)).toList();
}
