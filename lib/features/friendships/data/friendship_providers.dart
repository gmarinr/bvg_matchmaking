import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/env.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../domain/friendship.dart';
import '../domain/friendship_repository.dart';
import 'fake_friendship_repository.dart';
import 'supabase_friendship_repository.dart';

final friendshipRepositoryProvider = Provider<FriendshipRepository>((ref) {
  if (Env.isSupabaseConfigured) {
    return SupabaseFriendshipRepository(ref.watch(supabaseClientProvider));
  }
  return FakeFriendshipRepository();
});

class FriendshipPair {
  const FriendshipPair({required this.currentUserId, required this.otherUserId});

  final String currentUserId;
  final String otherUserId;

  @override
  bool operator ==(Object other) =>
      other is FriendshipPair &&
      other.currentUserId == currentUserId &&
      other.otherUserId == otherUserId;

  @override
  int get hashCode => Object.hash(currentUserId, otherUserId);
}

final friendshipBetweenProvider = FutureProvider.autoDispose
    .family<Friendship?, FriendshipPair>((ref, pair) {
      return ref.watch(friendshipRepositoryProvider).getBetween(
        currentUserId: pair.currentUserId,
        otherUserId: pair.otherUserId,
      );
    });
