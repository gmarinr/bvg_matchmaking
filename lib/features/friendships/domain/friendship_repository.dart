import 'friendship.dart';

abstract interface class FriendshipRepository {
  Future<List<Friendship>> getReceivedPending(String userId);

  Future<List<Friendship>> getSentPending(String userId);

  Future<List<Friendship>> getAccepted(String userId);

  Future<Friendship?> getBetween({
    required String currentUserId,
    required String otherUserId,
  });

  Future<Friendship> sendRequest({
    required String requesterId,
    required String addresseeId,
  });

  Future<Friendship> acceptRequest(String friendshipId);

  Future<Friendship> rejectRequest(String friendshipId);

  Future<Friendship> cancelRequest(String friendshipId);

  Future<Friendship> removeFriendship(String friendshipId);
}
