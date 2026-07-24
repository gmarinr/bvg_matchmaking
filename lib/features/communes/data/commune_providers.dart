import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/commune.dart';
import 'fake_commune_repository.dart';
import 'supabase_commune_repository.dart';

final communeRepositoryProvider = Provider((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseCommuneRepository(ref.watch(supabaseClientProvider));
  }
  return FakeCommuneRepository();
});

final communesProvider = FutureProvider.autoDispose<List<Commune>>(
  (ref) => ref.watch(communeRepositoryProvider).getCommunes(),
);
