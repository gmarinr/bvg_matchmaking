import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/commune.dart';
import '../domain/commune_repository.dart';

class SupabaseCommuneRepository implements CommuneRepository {
  SupabaseCommuneRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Commune>> getCommunes() async {
    final rows = await _client
        .from('communes')
        .select()
        .eq('is_active', true)
        .order('name');
    return rows
        .map((row) => Commune.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }
}
