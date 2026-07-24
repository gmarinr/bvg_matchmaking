import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/domain/enums.dart';
import '../../../core/supabase/supabase_error_mapper.dart';
import '../domain/match_participation.dart';
import '../domain/participation_repository.dart';

/// Supabase adapter for requests, participation and attendance.
class SupabaseParticipationRepository implements ParticipationRepository {
  SupabaseParticipationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MatchParticipation>> getParticipantsForMatch(
    String matchId,
  ) async {
    try {
      final rows = await _client
          .from('match_participations')
          .select()
          .eq('match_id', matchId)
          .order('created_at');
      return _asList(rows).map(MatchParticipation.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<List<MatchParticipation>> getMyParticipations(String userId) async {
    try {
      final rows = await _client
          .from('match_participations')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return _asList(rows).map(MatchParticipation.fromJson).toList();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<MatchParticipation> requestToJoin({
    required String matchId,
    required String userId,
  }) async {
    try {
      final row = await _client
          .from('match_participations')
          .insert({
            'match_id': matchId,
            'user_id': userId,
            'role': ParticipantRole.participant.wire,
            'participation_status': ParticipationStatus.pending.wire,
            'attendance_status': AttendanceStatus.unknown.wire,
          })
          .select()
          .single();
      return MatchParticipation.fromJson(_asMap(row));
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> respondToRequest({
    required String participationId,
    required bool accept,
  }) async {
    try {
      await _client
          .from('match_participations')
          .update({
            'participation_status':
                (accept
                        ? ParticipationStatus.accepted
                        : ParticipationStatus.rejected)
                    .wire,
          })
          .eq('id', participationId)
          .select('id')
          .single();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> setAttendance({
    required String participationId,
    required AttendanceStatus status,
  }) async {
    try {
      await _client
          .from('match_participations')
          .update({'attendance_status': status.wire})
          .eq('id', participationId)
          .select('id')
          .single();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  @override
  Future<void> cancelParticipation(String participationId) async {
    try {
      await _client
          .from('match_participations')
          .update({'participation_status': ParticipationStatus.cancelled.wire})
          .eq('id', participationId)
          .select('id')
          .single();
    } catch (error) {
      throw mapSupabaseError(error);
    }
  }

  static Map<String, dynamic> _asMap(Object value) =>
      Map<String, dynamic>.from(value as Map);

  static List<Map<String, dynamic>> _asList(Object value) =>
      (value as List).map((row) => _asMap(row)).toList();
}
