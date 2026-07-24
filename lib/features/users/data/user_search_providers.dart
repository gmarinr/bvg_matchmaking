import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/public_user_profile.dart';
import '../domain/user_search_repository.dart';
import 'fake_user_search_repository.dart';
import 'supabase_user_search_repository.dart';

final userSearchRepositoryProvider = Provider<UserSearchRepository>((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseUserSearchRepository(ref.watch(supabaseClientProvider));
  }
  return FakeUserSearchRepository();
});

final publicUserLookupProvider = FutureProvider.autoDispose
    .family<PublicUserProfile?, String>(
      (ref, userId) =>
          ref.watch(userSearchRepositoryProvider).findById(userId),
    );
