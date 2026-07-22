import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/supabase/supabase_error_mapper.dart';
import '../../../core/domain/enums.dart';
import '../domain/match.dart';
import '../domain/match_repository.dart';

/// Supabase adapter for match lifecycle and search operations.
class SupabaseMatchRepository implements MatchRepository {
  SupabaseMatchRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Match>> searchMatches(MatchFilter filter) async {
    try {
      var query = _client.from('matches_with_counts').select().inFilter(
        'status',
        ['open', 'full'],
      );

      if (filter.sportId != null) {
        query = query.eq('sport_id', filter.sportId!);
      }
      if (filter.commune != null && filter.commune!.trim().isNotEmpty) {
        query = query.ilike('commune', '%${filter.commune!.trim()}%');
      }
      if (filter.skillLevel != null) {
        query = query.eq('skill_level', filter.skillLevel!.wire);
      }
      if (filter.fromDate != null) {
        query = query.gte('start_at', filter.fromDate!.toIso8601String());
      }

      final rows = await query.order('start_at');
      return _asList(rows).map(Match.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<Match?> getMatch(String id) async {
    try {
      final row = await _client
          .from('matches_with_counts')
          .select()
          .eq('id', id)
          .maybeSingle();
      return row == null ? null : Match.fromJson(_asMap(row));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<Match> createMatch(Match match) async {
    try {
      final payload = match.toJson()
        ..remove('id')
        ..remove('created_at')
        ..remove('updated_at');
      final row = await _client
          .from('matches')
          .insert(payload)
          .select('id')
          .single();
      final created = await getMatch(_asMap(row)['id'] as String);
      if (created == null) throw StateError('Match was not returned');
      return created;
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<Match> updateMatch(Match match) async {
    try {
      final payload = match.toJson()
        ..remove('id')
        ..remove('organizer_id')
        ..remove('created_at')
        ..remove('updated_at');
      await _client.from('matches').update(payload).eq('id', match.id);
      final updated = await getMatch(match.id);
      if (updated == null) throw StateError('Match was not returned');
      return updated;
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> updateStatus(String matchId, MatchStatus status) async {
    try {
      await _client
          .from('matches')
          .update({'status': status.wire})
          .eq('id', matchId);
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<Match>> getMyOrganizedMatches(String userId) async {
    try {
      final rows = await _client
          .from('matches_with_counts')
          .select()
          .eq('organizer_id', userId)
          .order('start_at');
      return _asList(rows).map(Match.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static Map<String, dynamic> _asMap(Object value) =>
      Map<String, dynamic>.from(value as Map);

  static List<Map<String, dynamic>> _asList(Object value) =>
      (value as List).map((row) => _asMap(row)).toList();
}
