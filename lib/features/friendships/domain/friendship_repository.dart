import 'friendship.dart';

abstract interface class FriendshipRepository {
  Future<Friendship?> getBetween({
    required String currentUserId,
    required String otherUserId,
  });

  Future<Friendship> sendRequest({
    required String requesterId,
    required String addresseeId,
  });
}
